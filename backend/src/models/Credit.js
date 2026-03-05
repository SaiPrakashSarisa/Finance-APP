const mongoose = require('mongoose');

const CREDIT_TYPES = ['given', 'taken'];
const CREDIT_STATUSES = ['active', 'settled', 'partial'];

const creditSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        required: true,
        enum: {
            values: CREDIT_TYPES,
            message: '{VALUE} is not a valid credit type'
        }
    },
    subType: {
        type: String,
        enum: {
            values: ['account_credit', 'emi_loan', null],
            message: '{VALUE} is not a valid credit sub-type'
        },
        default: null
    },
    personName: {
        type: String,
        required: [true, 'Person name is required'],
        trim: true,
        maxlength: 100
    },
    amount: {
        type: Number,
        required: [true, 'Amount is required'],
        min: [0.01, 'Amount must be positive']
    },
    remainingAmount: {
        type: Number,
        required: true,
        min: 0
    },
    interestRate: {
        type: Number,
        default: 0,
        min: 0,
        max: 100
    },
    linkedAccountId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Account',
        default: null
    },
    status: {
        type: String,
        default: 'active',
        enum: {
            values: CREDIT_STATUSES,
            message: '{VALUE} is not a valid credit status'
        }
    },
    dueDate: {
        type: Date,
        default: null
    },
    notes: {
        type: String,
        trim: true,
        maxlength: 500,
        default: ''
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

creditSchema.index({ userId: 1, status: 1 });
creditSchema.index({ userId: 1, type: 1 });

module.exports = mongoose.model('Credit', creditSchema);
