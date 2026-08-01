const mongoose = require('mongoose');

const masterItemSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Item name is required'],
        trim: true,
        maxlength: 200
    },
    defaultCategoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
        default: null
    },
    defaultUnit: {
        type: String,
        default: 'unit',
        trim: true
    },
    lastUnitPrice: {
        type: Number,
        default: 0
    },
    purchaseCount: {
        type: Number,
        default: 0
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

masterItemSchema.index({ userId: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('MasterItem', masterItemSchema);
