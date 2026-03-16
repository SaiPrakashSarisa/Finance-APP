const Budget = require('../models/Budget');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');

const budgetService = {
    // Get all budgets for a user
    async getAll(userId) {
        return Budget.find({ userId }).populate('categoryId', 'name type color icon');
    },

    // Upsert a budget for a category
    async upsert(userId, categoryId, amount, yearMonth = 'default') {
        const query = { userId, categoryId, yearMonth };
        const update = { amount, period: 'monthly' };
        
        return Budget.findOneAndUpdate(query, update, {
            new: true,
            upsert: true,
            runValidators: true,
            setDefaultsOnInsert: true
        }).populate('categoryId', 'name type color icon');
    },

    // Delete a budget
    async delete(budgetId, userId) {
        return Budget.findOneAndDelete({ _id: budgetId, userId });
    },

    // Get budget progress for a specific month
    async getProgress(userId, month, year) {
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0, 23, 59, 59, 999);
        const yearMonthStr = `${year}-${String(month).padStart(2, '0')}`;

        // Get all budgets for the user
        const budgets = await Budget.find({
            userId,
            $or: [{ yearMonth: 'default' }, { yearMonth: yearMonthStr }]
        }).populate('categoryId', 'name type color icon');

        // Resolve active budgets (if override month exists, use it, else default)
        const activeBudgetsMap = new Map();
        budgets.forEach(b => {
            const current = activeBudgetsMap.get(b.categoryId._id.toString());
            if (!current || b.yearMonth !== 'default') {
                activeBudgetsMap.set(b.categoryId._id.toString(), b);
            }
        });

        const activeBudgets = Array.from(activeBudgetsMap.values());
        if (activeBudgets.length === 0) return []; // No budgets set

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
                amount: budgetedAmount, // the budget limit
                spent,
                remaining,
                percentageUsed: Math.round(percentageUsed),
                exceeded
            };
        });

        // Sort by percentage used descending
        progress.sort((a, b) => b.percentageUsed - a.percentageUsed);

        return progress;
    }
};

module.exports = budgetService;
