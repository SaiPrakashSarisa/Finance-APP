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
    yearMonth: {
        type: String, // e.g., '2023-10' or 'default'
        required: true,
        default: 'default'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Ensure a user can only have one budget per category per yearMonth
budgetSchema.index({ userId: 1, categoryId: 1, yearMonth: 1 }, { unique: true });

module.exports = mongoose.model('Budget', budgetSchema);
