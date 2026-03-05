const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const accountService = require('./accountService');
const creditService = require('./creditService');

const transactionService = {
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
            .populate('creditId', 'personName type subType amount remainingAmount status');
    },

    // Helper: apply balance effect for a transaction
    async _applyBalanceEffect(tx, multiplier = 1) {
        const amount = tx.amount * multiplier;
        switch (tx.type) {
            case 'income':
                await accountService.updateBalance(tx.accountId, amount);
                break;
            case 'expense':
                await accountService.updateBalance(tx.accountId, -amount);
                break;
            case 'transfer':
                await accountService.updateBalance(tx.accountId, -amount);
                await accountService.updateBalance(tx.toAccountId, amount);
                break;
            case 'credit_repay':
                if (tx.creditId && tx.accountId) {
                    const Credit = require('../models/Credit');
                    const credit = await Credit.findById(typeof tx.creditId === 'object' && tx.creditId._id ? tx.creditId._id : tx.creditId);
                    if (credit) {
                        if (credit.type === 'given') {
                            // Money coming back to you
                            await accountService.updateBalance(tx.accountId, amount);
                        } else {
                            // You're paying back
                            await accountService.updateBalance(tx.accountId, -amount);
                        }
                    }
                }
                break;
        }
    },

    // Create transaction and update balance
    async create(data) {
        // Handle credit_repay: validate and apply repayment
        if (data.type === 'credit_repay') {
            if (!data.creditId) throw new Error('Credit entry is required for repayment');
            await creditService.applyRepayment(data.creditId, data.userId, data.amount);
        }

        const transaction = new Transaction(data);
        await transaction.save();

        // Apply balance effect
        await this._applyBalanceEffect(transaction);

        return Transaction.findById(transaction._id)
            .populate('accountId', 'name type')
            .populate('toAccountId', 'name type')
            .populate('categoryId', 'name color icon type')
            .populate('creditId', 'personName type subType amount remainingAmount status');
    },

    // Update transaction: reverse old balance, apply edits, apply new balance
    async update(transactionId, userId, updates) {
        const existing = await Transaction.findOne({ _id: transactionId, userId });
        if (!existing) throw new Error('Transaction not found');

        // 1. Reverse old balance effect
        await this._applyBalanceEffect(existing, -1);

        // 2. Reverse old credit repayment if applicable
        if (existing.type === 'credit_repay' && existing.creditId) {
            await creditService.reverseRepayment(existing.creditId, userId, existing.amount);
        }

        // 3. Apply allowed updates
        const allowed = ['type', 'amount', 'accountId', 'toAccountId', 'categoryId', 'creditId', 'note', 'date'];
        allowed.forEach(field => {
            if (updates[field] !== undefined) existing[field] = updates[field];
        });
        if (existing.type !== 'transfer') existing.toAccountId = null;
        if (existing.type === 'transfer') existing.categoryId = null;
        if (existing.type !== 'credit_repay') existing.creditId = null;
        await existing.save();

        // 4. Apply new credit repayment if applicable
        if (existing.type === 'credit_repay' && existing.creditId) {
            await creditService.applyRepayment(existing.creditId, userId, existing.amount);
        }

        // 5. Apply new balance effect
        await this._applyBalanceEffect(existing);

        return Transaction.findById(existing._id)
            .populate('accountId', 'name type')
            .populate('toAccountId', 'name type')
            .populate('categoryId', 'name color icon type')
            .populate('creditId', 'personName type subType amount remainingAmount status');
    },

    // Delete transaction and reverse balance
    async delete(transactionId, userId) {
        const transaction = await Transaction.findOne({ _id: transactionId, userId });
        if (!transaction) throw new Error('Transaction not found');

        // Reverse balance effect
        await this._applyBalanceEffect(transaction, -1);

        // Reverse credit repayment if applicable
        if (transaction.type === 'credit_repay' && transaction.creditId) {
            await creditService.reverseRepayment(transaction.creditId, userId, transaction.amount);
        }

        await Transaction.deleteOne({ _id: transactionId });
        return transaction;
    }
};

module.exports = transactionService;
