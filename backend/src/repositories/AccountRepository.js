/**
 * Purpose: Repository for Account Operations
 * Responsibilities: Performs database queries and balance updates for Account model.
 * Dependencies: Account model
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 * Business Rules:
 *  - Every balance update must be atomic via $inc and execute inside MongoDB session transactions.
 */

const Account = require('../models/Account');

class AccountRepository {
    async create(data, session = null) {
        const options = session ? { session } : {};
        const accounts = await Account.create([data], options);
        return accounts[0];
    }

    async findById(id, userId, session = null) {
        const query = Account.findOne({ _id: id, userId });
        if (session) query.session(session);
        return query;
    }

    async findAll(userId) {
        return Account.find({ userId, isActive: true }).sort({ createdAt: 1 });
    }

    async updateBalance(accountId, amount, session = null) {
        const options = { new: true };
        if (session) options.session = session;

        return Account.findByIdAndUpdate(
            accountId,
            { $inc: { balance: amount } },
            options
        );
    }

    async update(id, userId, updates, session = null) {
        const options = { new: true };
        if (session) options.session = session;
        return Account.findOneAndUpdate({ _id: id, userId }, updates, options);
    }
}

module.exports = new AccountRepository();
