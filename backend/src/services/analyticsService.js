const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const Account = require('../models/Account');
const creditService = require('./creditService');
const User = require('../models/User');
const cache = require('../utils/cache');

const analyticsService = {
    // Helper to get date range based on month/year OR user settings
    async _getDateRange(userId, month, year) {
        let startDate, endDate;

        if (month !== null && year !== null && month !== undefined && year !== undefined) {
            startDate = new Date(year, month - 1, 1);
            endDate = new Date(year, month, 0, 23, 59, 59, 999);
        } else {
            const user = await User.findById(userId).select('settings');
            const range = user?.settings?.dashboardRange || '1m';

            endDate = new Date();
            endDate.setHours(23, 59, 59, 999);
            startDate = new Date();

            if (range === '1m') {
                startDate.setDate(1);
            } else if (range === '3m') {
                startDate.setMonth(endDate.getMonth() - 2);
                startDate.setDate(1);
            } else if (range === '6m') {
                startDate.setMonth(endDate.getMonth() - 5);
                startDate.setDate(1);
            } else if (range === '1y') {
                startDate.setMonth(endDate.getMonth() - 11);
                startDate.setDate(1);
            } else {
                startDate = new Date(0); // All time
            }
            startDate.setHours(0, 0, 0, 0);
        }
        return { startDate, endDate };
    },

    // Dashboard summary for a given range
    async getDashboard(userId, month, year) {
        const cacheKey = `${userId}:dashboard:${month || 'default'}:${year || 'default'}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        const { startDate, endDate } = await this._getDateRange(userId, month, year);

        const [totals, accounts, creditTotals] = await Promise.all([
            // Income/expense totals for range
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

        const income = totals.find(t => t._id === 'income')?.total || 0;
        const expense = totals.find(t => t._id === 'expense')?.total || 0;
        const totalBalance = accounts.reduce((sum, acc) => sum + acc.balance, 0);
        const netWorth = totalBalance + creditTotals.totalReceivables - creditTotals.totalLiabilities;

        const result = {
            income,
            expense,
            netSavings: income - expense,
            totalReceivables: creditTotals.totalReceivables,
            totalLiabilities: creditTotals.totalLiabilities,
            netWorth,
            accounts: accounts.map(a => ({ name: a.name, type: a.type, balance: a.balance }))
        };

        // Cache for 10 minutes
        cache.set(cacheKey, result, 600);
        return result;
    },

    // Expense breakdown by category
    async getCategoryBreakdown(userId, month, year) {
        const cacheKey = `${userId}:categories:${month || 'default'}:${year || 'default'}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        const { startDate, endDate } = await this._getDateRange(userId, month, year);

        const result = await Transaction.aggregate([
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

        cache.set(cacheKey, result, 600);
        return result;
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
    async getInsights(userId, month, year) {
        const cacheKey = `${userId}:insights:${month || 'default'}:${year || 'default'}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        const { startDate, endDate } = await this._getDateRange(userId, month, year);
        const dayOfMonth = (new Date()).getDate(); // Keep for daily avg calculation

        const [monthlyData, accounts, creditTotals, last30DaysExpenses] = await Promise.all([
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

        // Get highest spending category in range
        const highestCategory = await Transaction.aggregate([
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
                    total: { $sum: '$amount' }
                }
            },
            { $sort: { total: -1 } },
            { $limit: 1 }
        ]);

        const result = {
            savingsRate: Math.round(savingsRate * 100) / 100,
            avgDailyExpense: Math.round(avgDailyExpense * 100) / 100,
            burnRate: Math.round(burnRate),
            emergencyFundMonths: Math.round(emergencyFundMonths * 10) / 10,
            creditExposureRatio: Math.round(creditExposureRatio * 100) / 100,
            highestSpendingCategory: highestCategory[0] || null,
            income,
            expense,
            totalBalance,
            totalReceivables: creditTotals.totalReceivables,
            totalLiabilities: creditTotals.totalLiabilities
        };

        cache.set(cacheKey, result, 600);
        return result;
    },

    // Item price trend analytics
    async getItemTrends(userId, itemName) {
        if (!itemName) throw new Error('Item name is required for price trend query');
        const regex = new RegExp(itemName.trim(), 'i');

        const pipeline = [
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    isItemized: true,
                    'items.name': { $regex: regex }
                }
            },
            { $unwind: '$items' },
            {
                $match: {
                    'items.name': { $regex: regex }
                }
            },
            {
                $project: {
                    date: 1,
                    merchantName: 1,
                    itemName: '$items.name',
                    quantity: '$items.quantity',
                    unit: '$items.unit',
                    unitPrice: '$items.unitPrice',
                    totalPrice: '$items.totalPrice'
                }
            },
            { $sort: { date: 1 } }
        ];

        const records = await Transaction.aggregate(pipeline);

        if (records.length === 0) {
            return { itemName, history: [], minPrice: 0, maxPrice: 0, avgPrice: 0, priceChange: 0, inflationPercent: 0 };
        }

        const prices = records.map(r => r.unitPrice);
        const minPrice = Math.min(...prices);
        const maxPrice = Math.max(...prices);
        const avgPrice = Math.round((prices.reduce((a, b) => a + b, 0) / prices.length) * 100) / 100;
        
        const firstPrice = records[0].unitPrice;
        const latestPrice = records[records.length - 1].unitPrice;
        const priceChange = latestPrice - firstPrice;
        const inflationPercent = firstPrice > 0 ? Math.round(((latestPrice - firstPrice) / firstPrice * 100) * 100) / 100 : 0;

        return {
            itemName: records[0].itemName,
            history: records,
            minPrice,
            maxPrice,
            avgPrice,
            firstPrice,
            latestPrice,
            priceChange,
            inflationPercent
        };
    },

    // Personal inflation tracker for recurring items
    async getInflationTracker(userId) {
        const pipeline = [
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    isItemized: true
                }
            },
            { $unwind: '$items' },
            {
                $sort: { date: 1 }
            },
            {
                $group: {
                    _id: { $toLower: '$items.name' },
                    originalName: { $first: '$items.name' },
                    unit: { $first: '$items.unit' },
                    firstPurchaseDate: { $first: '$date' },
                    lastPurchaseDate: { $last: '$date' },
                    firstUnitPrice: { $first: '$items.unitPrice' },
                    lastUnitPrice: { $last: '$items.unitPrice' },
                    purchaseCount: { $sum: 1 }
                }
            },
            { $match: { purchaseCount: { $gte: 2 } } }
        ];

        const items = await Transaction.aggregate(pipeline);

        const tracker = items.map(item => {
            const priceDiff = item.lastUnitPrice - item.firstUnitPrice;
            const inflationPercent = item.firstUnitPrice > 0 
                ? Math.round(((item.lastUnitPrice - item.firstUnitPrice) / item.firstUnitPrice * 100) * 100) / 100 
                : 0;

            return {
                name: item.originalName,
                unit: item.unit,
                firstPrice: item.firstUnitPrice,
                lastPrice: item.lastUnitPrice,
                priceDiff,
                inflationPercent,
                purchaseCount: item.purchaseCount,
                firstDate: item.firstPurchaseDate,
                lastDate: item.lastPurchaseDate
            };
        });

        tracker.sort((a, b) => b.inflationPercent - a.inflationPercent);

        const overallInflation = tracker.length > 0
            ? Math.round((tracker.reduce((acc, i) => acc + i.inflationPercent, 0) / tracker.length) * 100) / 100
            : 0;

        return { overallInflation, items: tracker };
    }
};

module.exports = analyticsService;
