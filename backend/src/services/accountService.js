const Account = require('../models/Account');

const accountService = {
    // Get all accounts for a user
    async getAll(userId) {
        return Account.find({ userId, isActive: true }).sort({ createdAt: -1 });
    },

    // Get single account
    async getById(accountId, userId) {
        return Account.findOne({ _id: accountId, userId });
    },

    // Create account
    async create(data) {
        const account = new Account(data);
        return account.save();
    },

    // Update account
    async update(accountId, userId, data) {
        const allowed = ['name', 'type', 'currency', 'isActive', 'balance'];
        const updates = {};
        allowed.forEach(field => {
            if (data[field] !== undefined) updates[field] = data[field];
        });
        return Account.findOneAndUpdate(
            { _id: accountId, userId },
            updates,
            { new: true, runValidators: true }
        );
    },

    // Soft delete
    async delete(accountId, userId) {
        return Account.findOneAndUpdate(
            { _id: accountId, userId },
            { isActive: false },
            { new: true }
        );
    },

    // Update balance atomically
    async updateBalance(accountId, amount, session = null, allowNegative = true) {
        const options = { new: true };
        if (session) options.session = session;

        const account = await Account.findByIdAndUpdate(
            accountId,
            { $inc: { balance: amount } },
            options
        );

        if (!allowNegative && account && account.type !== 'credit_card' && account.balance < 0) {
            throw new Error(`Insufficient balance in account: ${account.name}`);
        }

        return account;
    }
};

module.exports = accountService;
