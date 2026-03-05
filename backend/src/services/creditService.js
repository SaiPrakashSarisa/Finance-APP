const mongoose = require('mongoose');
const Credit = require('../models/Credit');
const accountService = require('./accountService');

const creditService = {
    // Get all credits for a user
    async getAll(userId, filters = {}) {
        const query = { userId };
        if (filters.type) query.type = filters.type;
        if (filters.status) query.status = filters.status;

        return Credit.find(query)
            .populate('linkedAccountId', 'name type')
            .sort({ createdAt: -1 });
    },

    // Get single credit
    async getById(creditId, userId) {
        return Credit.findOne({ _id: creditId, userId })
            .populate('linkedAccountId', 'name type');
    },

    // Create credit entry and update balance
    async create(data) {
        data.remainingAmount = data.amount;

        // For taken + emi_loan, no account link
        if (data.type === 'taken' && data.subType === 'emi_loan') {
            data.linkedAccountId = null;
        }

        const credit = new Credit(data);
        await credit.save();

        // Update account balance
        if (data.type === 'given' && data.linkedAccountId) {
            await accountService.updateBalance(data.linkedAccountId, -data.amount);
        } else if (data.type === 'taken' && data.subType === 'account_credit' && data.linkedAccountId) {
            await accountService.updateBalance(data.linkedAccountId, data.amount);
        }
        // emi_loan: no balance update

        return Credit.findById(credit._id)
            .populate('linkedAccountId', 'name type');
    },

    // Update credit (editable fields only)
    async update(creditId, userId, updates) {
        const allowed = ['personName', 'dueDate', 'notes', 'interestRate'];
        const data = {};
        allowed.forEach(field => {
            if (updates[field] !== undefined) data[field] = updates[field];
        });

        return Credit.findOneAndUpdate(
            { _id: creditId, userId },
            data,
            { new: true, runValidators: true }
        ).populate('linkedAccountId', 'name type');
    },

    // Record repayment (called internally by transactionService)
    async applyRepayment(creditId, userId, repayAmount) {
        const credit = await Credit.findOne({ _id: creditId, userId });
        if (!credit) throw new Error('Credit entry not found');
        if (credit.status === 'settled') throw new Error('Credit is already settled');
        if (repayAmount > credit.remainingAmount) {
            throw new Error('Repayment amount exceeds remaining amount');
        }

        credit.remainingAmount -= repayAmount;
        credit.status = credit.remainingAmount === 0 ? 'settled' : 'partial';
        await credit.save();

        return credit;
    },

    // Reverse a repayment (called when deleting/editing a credit_repay transaction)
    async reverseRepayment(creditId, userId, repayAmount) {
        const credit = await Credit.findOne({ _id: creditId, userId });
        if (!credit) throw new Error('Credit entry not found');

        credit.remainingAmount += repayAmount;
        if (credit.remainingAmount > credit.amount) {
            credit.remainingAmount = credit.amount;
        }
        credit.status = credit.remainingAmount === credit.amount ? 'active' : 'partial';
        await credit.save();

        return credit;
    },

    // Get totals
    async getTotals(userId) {
        const [receivables, liabilities] = await Promise.all([
            Credit.aggregate([
                { $match: { userId: new mongoose.Types.ObjectId(userId), type: 'given', status: { $ne: 'settled' } } },
                { $group: { _id: null, total: { $sum: '$remainingAmount' } } }
            ]),
            Credit.aggregate([
                { $match: { userId: new mongoose.Types.ObjectId(userId), type: 'taken', status: { $ne: 'settled' } } },
                { $group: { _id: null, total: { $sum: '$remainingAmount' } } }
            ])
        ]);

        return {
            totalReceivables: receivables[0]?.total || 0,
            totalLiabilities: liabilities[0]?.total || 0
        };
    }
};

module.exports = creditService;
