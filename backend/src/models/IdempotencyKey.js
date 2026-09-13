const mongoose = require('mongoose');

const idempotencyKeySchema = new mongoose.Schema({
    key: {
        type: String,
        required: true,
        unique: true,
        index: true,
        trim: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    path: {
        type: String,
        required: true
    },
    method: {
        type: String,
        required: true
    },
    status: {
        type: String,
        enum: ['processing', 'completed', 'failed'],
        default: 'processing'
    },
    responseStatus: {
        type: Number,
        default: null
    },
    responseBody: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 86400 // TTL index: automatically deleted after 24 hours
    }
});

module.exports = mongoose.model('IdempotencyKey', idempotencyKeySchema);
