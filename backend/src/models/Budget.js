const mongoose = require('mongoose');

const budgetSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    categoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
        required: true
    },
    amount: {
        type: Number,
        required: [true, 'Budget amount is required'],
        min: [0, 'Budget amount cannot be negative']
    },
    period: {
        type: String,
        required: true,
        enum: ['monthly'],
        default: 'monthly'
    },
    // The YYYY-MM starting from which this budget amount is effective
    validFrom: {
        type: String,
        required: true,
        match: /^\d{4}-\d{2}$/ // Enforces YYYY-MM format
    }
}, { timestamps: true });

// Ensure a user can only have one budget per category per "validFrom" snapshot month
budgetSchema.index({ userId: 1, categoryId: 1, validFrom: 1 }, { unique: true });

module.exports = mongoose.model('Budget', budgetSchema);
