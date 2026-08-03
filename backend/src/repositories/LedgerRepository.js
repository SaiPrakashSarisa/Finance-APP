/**
 * Purpose: Repository for Ledger Operations
 * Responsibilities: Handles atomic database queries for LedgerEntry model.
 * Dependencies: LedgerEntry model, mongoose
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 * Business Rules:
 *  - Only insert operations are permitted on LedgerEntries. No updates or deletes.
 */

const LedgerEntry = require('../models/LedgerEntry');

class LedgerRepository {
    /**
     * Create an immutable ledger entry
     * @param {Object} data Entry payload
     * @param {ClientSession} [session] Mongoose transaction session
     */
    async create(data, session = null) {
        const options = session ? { session } : {};
        const entries = await LedgerEntry.create([data], options);
        return entries[0];
    }

    /**
     * Calculate derived balance for an account by summing all ledger entries
     * @param {String} accountId Account ObjectId
     * @param {String} userId User ObjectId
     */
    async calculateDerivedBalance(accountId, userId) {
        const result = await LedgerEntry.aggregate([
            { $match: { accountId: new (require('mongoose').Types.ObjectId)(accountId), userId: new (require('mongoose').Types.ObjectId)(userId) } },
            { $group: { _id: '$accountId', totalBalance: { $sum: '$amount' } } }
        ]);

        return result.length > 0 ? result[0].totalBalance : 0;
    }

    /**
     * Get ledger history for an account
     */
    async findByAccount(accountId, userId, limit = 50, page = 1) {
        const skip = (page - 1) * limit;
        return LedgerEntry.find({ accountId, userId })
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .populate('transactionId', 'type amount date categoryId note');
    }
}

module.exports = new LedgerRepository();
