const mongoose = require('mongoose');

const ACCOUNT_TYPES = ['bank', 'cash', 'credit_card', 'wallet', 'investment'];

const accountSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Account name is required'],
        trim: true,
        maxlength: 100
    },
    type: {
        type: String,
        required: true,
        enum: {
            values: ACCOUNT_TYPES,
            message: '{VALUE} is not a valid account type'
        }
    },
    balance: {
        type: Number,
        default: 0
    },
    currency: {
        type: String,
        default: 'INR',
        uppercase: true
    },
    isActive: {
        type: Boolean,
        default: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

accountSchema.index({ userId: 1, isActive: 1 });
accountSchema.index({ userId: 1, type: 1 });

// Prevent negative balance for non-credit-card accounts
accountSchema.pre('save', function (next) {
    if (this.type !== 'credit_card' && this.balance < 0) {
        return next(new Error('Negative balance is not allowed for non-credit-card accounts'));
    }
    next();
});

module.exports = mongoose.model('Account', accountSchema);
