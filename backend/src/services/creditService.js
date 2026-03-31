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
    async create(data, session = null) {
        data.remainingAmount = data.amount;

        // For taken + emi_loan, no account link
        if (data.type === 'taken' && data.subType === 'emi_loan') {
            data.linkedAccountId = null;
        }

        const options = session ? { session } : {};
        const credit = new Credit(data);
        await credit.save(options);

        // Update account balance
        if (data.type === 'given' && data.linkedAccountId) {
            await accountService.updateBalance(data.linkedAccountId, -data.amount, session);
        } else if (data.type === 'taken' && data.subType === 'account_credit' && data.linkedAccountId) {
            await accountService.updateBalance(data.linkedAccountId, data.amount, session);
        }
        // emi_loan: no balance update

        return Credit.findById(credit._id)
            .populate('linkedAccountId', 'name type')
            .session(session);
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
    async applyRepayment(creditId, userId, repayAmount, session = null) {
        const query = { 
            _id: creditId, 
            userId, 
            status: { $ne: 'settled' },
            remainingAmount: { $gte: repayAmount }
        };
        const options = { new: true, runValidators: true };
        if (session) options.session = session;

        // Use aggregation pipeline in findOneAndUpdate for atomic status & amount update
        const updated = await Credit.findOneAndUpdate(
            query,
            [
                {
                    $set: {
                        remainingAmount: { $subtract: ['$remainingAmount', repayAmount] }
                    }
                },
                {
                    $set: {
                        status: {
                            $cond: { 
                                if: { $lte: ['$remainingAmount', 0] }, 
                                then: 'settled', 
                                else: 'partial' 
                            }
                        }
                    }
                }
            ],
            options
        );

        if (!updated) {
            // Check why it failed
            const credit = await Credit.findOne({ _id: creditId, userId });
            if (!credit) throw new Error('Credit entry not found');
            if (credit.status === 'settled') throw new Error('Credit is already settled');
            if (repayAmount > credit.remainingAmount) {
                throw new Error(`Repayment amount (${repayAmount}) exceeds remaining amount (${credit.remainingAmount})`);
            }
            throw new Error('Repayment failed due to concurrent update or invalid state');
        }

        return updated;
    },

    // Reverse a repayment (called when deleting/editing a credit_repay transaction)
    async reverseRepayment(creditId, userId, repayAmount, session = null) {
        const query = { _id: creditId, userId };
        const options = { new: true };
        if (session) options.session = session;

        const updated = await Credit.findOneAndUpdate(
            query,
            [
                {
                    $set: {
                        remainingAmount: { $add: ['$remainingAmount', repayAmount] }
                    }
                },
                {
                    $set: {
                        // Ensure remaining amount does not exceed original amount
                        remainingAmount: {
                            $cond: {
                                if: { $gt: ['$remainingAmount', '$amount'] },
                                then: '$amount',
                                else: '$remainingAmount'
                            }
                        }
                    }
                },
                {
                    $set: {
                        status: {
                            $cond: {
                                if: { $eq: ['$remainingAmount', '$amount'] },
                                then: 'active',
                                else: 'partial'
                            }
                        }
                    }
                }
            ],
            options
        );

        if (!updated) throw new Error('Credit entry not found during reversal');

        return updated;
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
