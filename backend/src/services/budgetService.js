const Budget = require('../models/Budget');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');

// Helper to get effective budgets for a specific month
async function getEffectiveBudgetsForMonth(userId, targetYearMonth) {
    // Find all budgets with validFrom <= targetYearMonth
    const budgets = await Budget.find({
        userId,
        validFrom: { $lte: targetYearMonth }
    })
    .sort({ validFrom: -1 }) // Sort latest first
    .populate('categoryId', 'name type color icon');

    // Filter to keep only the highest validFrom per category
    const activeBudgetsMap = new Map();
    budgets.forEach(b => {
        const catId = b.categoryId._id.toString();
        if (!activeBudgetsMap.has(catId)) {
            activeBudgetsMap.set(catId, b);
        }
    });

    return Array.from(activeBudgetsMap.values());
}

const budgetService = {
    // Get all budgets for the CURRENT month (since Settings only shows/edits current month)
    async getAll(userId) {
        const now = new Date();
        const targetYearMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
        
        const activeBudgets = await getEffectiveBudgetsForMonth(userId, targetYearMonth);
        // Filter out tombstones (amount === 0 means deleted for this and future months)
        return activeBudgets.filter(b => b.amount > 0);
    },

    // Upsert a budget for a category (Always acts on CURRENT month)
    async upsert(userId, categoryId, amount) {
        const now = new Date();
        const currentYearMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
        
        const query = { userId, categoryId, validFrom: currentYearMonth };
        const update = { amount, period: 'monthly' };
        
        return Budget.findOneAndUpdate(query, update, {
            new: true,
            upsert: true,
            runValidators: true,
            setDefaultsOnInsert: true
        }).populate('categoryId', 'name type color icon');
    },

    // Delete a budget - soft deletes by creating a 0-amount tombstone for current month onwards
    async delete(budgetId, userId) {
        const budget = await Budget.findOne({ _id: budgetId, userId });
        if (!budget) return null;

        const now = new Date();
        const currentYearMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

        // Create a tombstone for current month
        const query = { userId, categoryId: budget.categoryId, validFrom: currentYearMonth };
        const update = { amount: 0, period: 'monthly' };

        return Budget.findOneAndUpdate(query, update, {
            new: true,
            upsert: true,
            runValidators: true
        });
    },

    // Get budget progress for a specific month
    async getProgress(userId, month, year) {
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0, 23, 59, 59, 999);
        const targetYearMonth = `${year}-${String(month).padStart(2, '0')}`;

        let activeBudgets = await getEffectiveBudgetsForMonth(userId, targetYearMonth);
        activeBudgets = activeBudgets.filter(b => b.amount > 0);

        if (activeBudgets.length === 0) return [];

        const categoryIds = activeBudgets.map(b => b.categoryId._id);

        // Aggregate actual spending for these categories in the given month
        const spending = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    type: 'expense',
                    categoryId: { $in: categoryIds },
                    date: { $gte: startDate, $lte: endDate }
                }
            },
            {
                $group: {
                    _id: '$categoryId',
                    totalSpent: { $sum: '$amount' }
                }
            }
        ]);

        const spendingMap = new Map(spending.map(s => [s._id.toString(), s.totalSpent]));

        // Combine budgets with spending calculate progress
        const progress = activeBudgets.map(budget => {
            const spent = spendingMap.get(budget.categoryId._id.toString()) || 0;
            const budgetedAmount = budget.amount;
            const remaining = budgetedAmount - spent;
            const percentageUsed = budgetedAmount > 0 ? (spent / budgetedAmount) * 100 : 0;
            const exceeded = spent > budgetedAmount;

            return {
                budgetId: budget._id,
                category: budget.categoryId,
                amount: budgetedAmount,
                spent,
                remaining,
                percentageUsed: Math.round(percentageUsed),
                exceeded
            };
        });

        // Sort by percentage used descending
        progress.sort((a, b) => b.percentageUsed - a.percentageUsed);

        return progress;
    },

    // Calculate long-term analytics trailing over a specific month range
    async getAnalytics(userId, fromMonth, fromYear, toMonth, toYear) {
        const results = [];
        let currentYear = parseInt(fromYear);
        let currentMonth = parseInt(fromMonth);
        const targetYear = parseInt(toYear);
        const targetMonth = parseInt(toMonth);
        
        let successMonths = 0;
        let exceededMonths = 0;

        // Failsafe iteration limit (max 60 months)
        let loops = 0;

        while ((currentYear < targetYear || (currentYear === targetYear && currentMonth <= targetMonth)) && loops < 60) {
            const progress = await this.getProgress(userId, currentMonth, currentYear);
            
            let monthTotalBudget = 0;
            let monthTotalSpent = 0;
            let monthExceeded = false;

            progress.forEach(p => {
                monthTotalBudget += p.amount;
                monthTotalSpent += p.spent;
                if (p.exceeded) monthExceeded = true;
            });

            // Only count towards win-rate if they actually had budgets set
            if (progress.length > 0) {
                if (monthExceeded) exceededMonths++;
                else successMonths++;
            }

            results.push({
                month: currentMonth,
                year: currentYear,
                label: `${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][currentMonth - 1]} ${currentYear}`,
                totalBudget: monthTotalBudget,
                totalSpent: monthTotalSpent,
                isExceeded: monthExceeded,
                hasBudgets: progress.length > 0
            });

            // Increment Month/Year
            currentMonth++;
            if (currentMonth > 12) {
                currentMonth = 1;
                currentYear++;
            }
            loops++;
        }

        return {
            successMonths,
            exceededMonths,
            trends: results
        };
    }
};

module.exports = budgetService;
