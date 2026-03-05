const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const Account = require('../models/Account');
const creditService = require('./creditService');

const analyticsService = {
    // Dashboard summary for a given month
    async getDashboard(userId, month, year) {
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0, 23, 59, 59, 999);

        const [monthlyTotals, accounts, creditTotals] = await Promise.all([
            // Monthly income/expense (excluding transfers)
            Transaction.aggregate([
                {
                    $match: {
                        userId: new mongoose.Types.ObjectId(userId),
                        date: { $gte: startDate, $lte: endDate },
                        type: { $in: ['income', 'expense'] }
                    }
                },
                {
                    $group: {
                        _id: '$type',
                        total: { $sum: '$amount' }
                    }
                }
            ]),
            // All active account balances
            Account.find({ userId, isActive: true }).select('name type balance'),
            // Credit totals
            creditService.getTotals(userId)
        ]);

        const income = monthlyTotals.find(t => t._id === 'income')?.total || 0;
        const expense = monthlyTotals.find(t => t._id === 'expense')?.total || 0;
        const totalBalance = accounts.reduce((sum, acc) => sum + acc.balance, 0);
        const netWorth = totalBalance + creditTotals.totalReceivables - creditTotals.totalLiabilities;

        return {
            monthlyIncome: income,
            monthlyExpense: expense,
            netSavings: income - expense,
            totalReceivables: creditTotals.totalReceivables,
            totalLiabilities: creditTotals.totalLiabilities,
            netWorth,
            accounts: accounts.map(a => ({ name: a.name, type: a.type, balance: a.balance }))
        };
    },

    // Expense breakdown by category
    async getCategoryBreakdown(userId, month, year) {
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0, 23, 59, 59, 999);

        return Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    type: 'expense',
                    date: { $gte: startDate, $lte: endDate }
                }
            },
            {
                $lookup: {
                    from: 'categories',
                    localField: 'categoryId',
                    foreignField: '_id',
                    as: 'category'
                }
            },
            { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } },
            {
                $group: {
                    _id: '$categoryId',
                    name: { $first: { $ifNull: ['$category.name', 'Uncategorized'] } },
                    color: { $first: { $ifNull: ['$category.color', '#94a3b8'] } },
                    icon: { $first: { $ifNull: ['$category.icon', '📁'] } },
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            },
            { $sort: { total: -1 } }
        ]);
    },

    // Monthly trend (last 6 months)
    async getMonthlyTrend(userId) {
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
        sixMonthsAgo.setDate(1);
        sixMonthsAgo.setHours(0, 0, 0, 0);

        return Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    date: { $gte: sixMonthsAgo },
                    type: { $in: ['income', 'expense'] }
                }
            },
            {
                $group: {
                    _id: {
                        year: { $year: '$date' },
                        month: { $month: '$date' },
                        type: '$type'
                    },
                    total: { $sum: '$amount' }
                }
            },
            { $sort: { '_id.year': 1, '_id.month': 1 } }
        ]);
    },

    // Smart insights
    async getInsights(userId) {
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const dayOfMonth = now.getDate();

        const [monthlyData, accounts, creditTotals, last30DaysExpenses] = await Promise.all([
            Transaction.aggregate([
                {
                    $match: {
                        userId: new mongoose.Types.ObjectId(userId),
                        date: { $gte: startOfMonth },
                        type: { $in: ['income', 'expense'] }
                    }
                },
                {
                    $group: {
                        _id: '$type',
                        total: { $sum: '$amount' }
                    }
                }
            ]),
            Account.find({ userId, isActive: true }).select('balance'),
            creditService.getTotals(userId),
            Transaction.aggregate([
                {
                    $match: {
                        userId: new mongoose.Types.ObjectId(userId),
                        type: 'expense',
                        date: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
                    }
                },
                { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
            ])
        ]);

        const income = monthlyData.find(t => t._id === 'income')?.total || 0;
        const expense = monthlyData.find(t => t._id === 'expense')?.total || 0;
        const totalBalance = accounts.reduce((sum, acc) => sum + acc.balance, 0);
        const totalAssets = totalBalance + creditTotals.totalReceivables;
        const last30Expense = last30DaysExpenses[0]?.total || 0;

        const savingsRate = income > 0 ? ((income - expense) / income * 100) : 0;
        const avgDailyExpense = dayOfMonth > 0 ? expense / dayOfMonth : 0;
        const burnRate = avgDailyExpense > 0 ? totalBalance / avgDailyExpense : 0;
        const emergencyFundMonths = last30Expense > 0 ? totalBalance / last30Expense : 0;
        const creditExposureRatio = totalAssets > 0
            ? (creditTotals.totalLiabilities / totalAssets * 100)
            : 0;

        // Get highest spending category this month
        const highestCategory = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    type: 'expense',
                    date: { $gte: startOfMonth }
                }
            },
            {
                $lookup: {
                    from: 'categories',
                    localField: 'categoryId',
                    foreignField: '_id',
                    as: 'category'
                }
            },
            { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } },
            {
                $group: {
                    _id: '$categoryId',
                    name: { $first: { $ifNull: ['$category.name', 'Uncategorized'] } },
                    total: { $sum: '$amount' }
                }
            },
            { $sort: { total: -1 } },
            { $limit: 1 }
        ]);

        return {
            savingsRate: Math.round(savingsRate * 100) / 100,
            avgDailyExpense: Math.round(avgDailyExpense * 100) / 100,
            burnRate: Math.round(burnRate),
            emergencyFundMonths: Math.round(emergencyFundMonths * 10) / 10,
            creditExposureRatio: Math.round(creditExposureRatio * 100) / 100,
            highestSpendingCategory: highestCategory[0] || null,
            monthlyIncome: income,
            monthlyExpense: expense,
            totalBalance,
            totalReceivables: creditTotals.totalReceivables,
            totalLiabilities: creditTotals.totalLiabilities
        };
    }
};

module.exports = analyticsService;
