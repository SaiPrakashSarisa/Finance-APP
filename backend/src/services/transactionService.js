const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const Merchant = require('../models/Merchant');
const MasterItem = require('../models/MasterItem');
const accountService = require('./accountService');
const creditService = require('./creditService');
const { runInTransaction } = require('../utils/dbSession');
const cache = require('../utils/cache');

const transactionService = {
    // Helper to process merchant & master item records
    async _processItemsAndMerchant(data, session = null) {
        if (data.merchantName && data.merchantName.trim()) {
            const trimmedName = data.merchantName.trim();
            const options = { upsert: true, new: true, runValidators: true };
            if (session) options.session = session;
            const merchant = await Merchant.findOneAndUpdate(
                { userId: data.userId, name: trimmedName },
                { $inc: { transactionCount: 1 } },
                options
            );
            if (merchant) data.merchantId = merchant._id;
        }

        if (Array.isArray(data.items) && data.items.length > 0) {
            data.isItemized = true;
            for (const item of data.items) {
                if (item.totalPrice === undefined || item.totalPrice === null) {
                    item.totalPrice = (item.quantity || 1) * (item.unitPrice || 0) - (item.discount || 0);
                }
                if (item.name && item.name.trim()) {
                    const trimmedItem = item.name.trim();
                    const options = { upsert: true, new: true };
                    if (session) options.session = session;
                    const master = await MasterItem.findOneAndUpdate(
                        { userId: data.userId, name: trimmedItem },
                        { 
                            $set: { lastUnitPrice: item.unitPrice, defaultUnit: item.unit || 'unit' },
                            $inc: { purchaseCount: 1 }
                        },
                        options
                    );
                    if (master) item.masterItemId = master._id;
                }
            }
        }
    },

    // Get transactions with filters
    async getAll(userId, filters = {}) {
        const query = { userId };

        if (filters.accountId) {
            query.$or = [
                { accountId: filters.accountId },
                { toAccountId: filters.accountId }
            ];
        }
        if (filters.type) query.type = filters.type;
        if (filters.categoryId) query.categoryId = filters.categoryId;
        if (filters.creditId) query.creditId = filters.creditId;
        if (filters.merchantId) query.merchantId = filters.merchantId;

        if (filters.startDate || filters.endDate) {
            query.date = {};
            if (filters.startDate) query.date.$gte = new Date(filters.startDate);
            if (filters.endDate) query.date.$lte = new Date(filters.endDate);
        }

        if (filters.minAmount || filters.maxAmount) {
            query.amount = {};
            if (filters.minAmount) query.amount.$gte = Number(filters.minAmount);
            if (filters.maxAmount) query.amount.$lte = Number(filters.maxAmount);
        }

        const page = parseInt(filters.page) || 1;
        const limit = parseInt(filters.limit) || 50;
        const skip = (page - 1) * limit;

        const [transactions, total] = await Promise.all([
            Transaction.find(query)
                .populate('accountId', 'name type')
                .populate('toAccountId', 'name type')
                .populate('categoryId', 'name color icon type')
                .populate('creditId', 'personName type subType amount remainingAmount status')
                .populate('merchantId', 'name icon')
                .sort({ date: -1, createdAt: -1 })
                .skip(skip)
                .limit(limit),
            Transaction.countDocuments(query)
        ]);

        return { transactions, total, page, pages: Math.ceil(total / limit) };
    },

    // Get single transaction
    async getById(transactionId, userId) {
        return Transaction.findOne({ _id: transactionId, userId })
            .populate('accountId', 'name type')
            .populate('toAccountId', 'name type')
            .populate('categoryId', 'name color icon type')
            .populate('creditId', 'personName type subType amount remainingAmount status')
            .populate('merchantId', 'name icon');
    },

    // Helper: apply balance effect for a transaction
    async _applyBalanceEffect(tx, multiplier = 1, session = null) {
        const amount = tx.amount * multiplier;
        switch (tx.type) {
            case 'income':
                await accountService.updateBalance(tx.accountId, amount, session);
                break;
            case 'expense':
                await accountService.updateBalance(tx.accountId, -amount, session);
                break;
            case 'transfer':
                await accountService.updateBalance(tx.accountId, -amount, session);
                await accountService.updateBalance(tx.toAccountId, amount, session);
                break;
            case 'credit_repay':
                if (tx.creditId && tx.accountId) {
                    const Credit = require('../models/Credit');
                    const credit = await Credit.findById(typeof tx.creditId === 'object' && tx.creditId._id ? tx.creditId._id : tx.creditId).session(session);
                    if (credit) {
                        if (credit.type === 'given') {
                            // Money coming back to you
                            await accountService.updateBalance(tx.accountId, amount, session);
                        } else {
                            // You're paying back
                            await accountService.updateBalance(tx.accountId, -amount, session);
                        }
                    }
                }
                break;
        }
    },

    // Create transaction and update balance
    async create(data) {
        return runInTransaction(async (session) => {
            // Process Merchant & Items
            await this._processItemsAndMerchant(data, session);

            // Handle credit_repay: validate and apply repayment
            if (data.type === 'credit_repay') {
                if (!data.creditId) throw new Error('Credit entry is required for repayment');
                await creditService.applyRepayment(data.creditId, data.userId, data.amount, session);
            }

            const transaction = new Transaction(data);
            await transaction.save({ session });

            // Apply balance effect
            await this._applyBalanceEffect(transaction, 1, session);

            // Invalidate cache
            cache.clearUserCache(data.userId);

            return Transaction.findById(transaction._id)
                .populate('accountId', 'name type')
                .populate('toAccountId', 'name type')
                .populate('categoryId', 'name color icon type')
                .populate('creditId', 'personName type subType amount remainingAmount status')
                .populate('merchantId', 'name icon')
                .session(session);
        });
    },

    // Update transaction: reverse old balance, apply edits, apply new balance
    async update(transactionId, userId, updates) {
        return runInTransaction(async (session) => {
            const existing = await Transaction.findOne({ _id: transactionId, userId }).session(session);
            if (!existing) throw new Error('Transaction not found');

            // 1. Reverse old balance effect
            await this._applyBalanceEffect(existing, -1, session);

            // 2. Reverse old credit repayment if applicable
            if (existing.type === 'credit_repay' && existing.creditId) {
                await creditService.reverseRepayment(existing.creditId, userId, existing.amount, session);
            }

            // 3. Apply allowed updates
            updates.userId = userId;
            await this._processItemsAndMerchant(updates, session);

            const allowed = ['type', 'amount', 'accountId', 'toAccountId', 'categoryId', 'creditId', 'note', 'date', 'merchantId', 'merchantName', 'isItemized', 'items'];
            allowed.forEach(field => {
                if (updates[field] !== undefined) existing[field] = updates[field];
            });
            if (existing.type !== 'transfer') existing.toAccountId = null;
            if (existing.type === 'transfer') existing.categoryId = null;
            if (existing.type !== 'credit_repay') existing.creditId = null;
            await existing.save({ session });

            // 4. Apply new credit repayment if applicable
            if (existing.type === 'credit_repay' && existing.creditId) {
                await creditService.applyRepayment(existing.creditId, userId, existing.amount, session);
            }

            // 5. Apply new balance effect
            await this._applyBalanceEffect(existing, 1, session);

            // Invalidate cache
            cache.clearUserCache(userId);

            return Transaction.findById(existing._id)
                .populate('accountId', 'name type')
                .populate('toAccountId', 'name type')
                .populate('categoryId', 'name color icon type')
                .populate('creditId', 'personName type subType amount remainingAmount status')
                .populate('merchantId', 'name icon')
                .session(session);
        });
    },

    // Delete transaction and reverse balance
    async delete(transactionId, userId) {
        return runInTransaction(async (session) => {
            const transaction = await Transaction.findOne({ _id: transactionId, userId }).session(session);
            if (!transaction) throw new Error('Transaction not found');

            // Reverse balance effect
            await this._applyBalanceEffect(transaction, -1, session);

            // Reverse credit repayment if applicable
            if (transaction.type === 'credit_repay' && transaction.creditId) {
                await creditService.reverseRepayment(transaction.creditId, userId, transaction.amount, session);
            }

            await Transaction.deleteOne({ _id: transactionId }, { session });

            // Invalidate cache
            cache.clearUserCache(userId);

            return transaction;
        });
    }
};

module.exports = transactionService;
