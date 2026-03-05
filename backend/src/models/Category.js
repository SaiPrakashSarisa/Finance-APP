const mongoose = require('mongoose');

const CATEGORY_TYPES = ['income', 'expense'];

const categorySchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Category name is required'],
        trim: true,
        maxlength: 50
    },
    type: {
        type: String,
        required: true,
        enum: {
            values: CATEGORY_TYPES,
            message: '{VALUE} is not a valid category type'
        }
    },
    color: {
        type: String,
        default: '#6366f1'
    },
    icon: {
        type: String,
        default: '📁'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

categorySchema.index({ userId: 1, type: 1 });

module.exports = mongoose.model('Category', categorySchema);
