const mongoose = require('mongoose');

const TRANSACTION_TYPES = ['income', 'expense', 'transfer', 'credit_repay'];

const transactionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    accountId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Account',
        required: true
    },
    type: {
        type: String,
        required: true,
        enum: {
            values: TRANSACTION_TYPES,
            message: '{VALUE} is not a valid transaction type'
        }
    },
    amount: {
        type: Number,
        required: [true, 'Amount is required'],
        min: [0.01, 'Amount must be positive']
    },
    categoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
        default: null
    },
    note: {
        type: String,
        trim: true,
        maxlength: 500,
        default: ''
    },
    date: {
        type: Date,
        required: true,
        default: Date.now
    },
    toAccountId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Account',
        default: null
    },
    creditId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Credit',
        default: null
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

transactionSchema.index({ userId: 1, date: -1 });
transactionSchema.index({ userId: 1, accountId: 1, date: -1 });
transactionSchema.index({ userId: 1, type: 1, date: -1 });
transactionSchema.index({ userId: 1, creditId: 1 });
transactionSchema.index({ accountId: 1 });

// Validate toAccountId for transfers
transactionSchema.pre('validate', function (next) {
    if (this.type === 'transfer' && !this.toAccountId) {
        return next(new Error('Destination account is required for transfers'));
    }
    if (this.type === 'transfer' && this.accountId.toString() === this.toAccountId.toString()) {
        return next(new Error('Source and destination accounts must be different'));
    }
    next();
});

module.exports = mongoose.model('Transaction', transactionSchema);
