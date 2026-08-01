const mongoose = require('mongoose');

const merchantSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Merchant name is required'],
        trim: true,
        maxlength: 150
    },
    defaultCategoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
        default: null
    },
    icon: {
        type: String,
        default: '🏪'
    },
    transactionCount: {
        type: Number,
        default: 0
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

merchantSchema.index({ userId: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('Merchant', merchantSchema);
