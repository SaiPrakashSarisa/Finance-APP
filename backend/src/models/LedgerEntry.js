/**
 * Purpose: Authoritative Immutable Financial Ledger Model
 * Responsibilities: Records every balance update event. Ledger entries are immutable and form the source of truth.
 * Dependencies: mongoose, constants
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 * Business Rules:
 *  - Ledger entries can never be modified or deleted.
 *  - Every financial transaction, opening balance entry, or adjustment MUST create a LedgerEntry.
 *  - Derived balance = sum of amounts of all LedgerEntries for an account.
 */

const mongoose = require('mongoose');
const { LEDGER_TYPES } = require('../constants');

const ledgerEntrySchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    accountId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Account',
        required: true,
        index: true
    },
    type: {
        type: String,
        required: true,
        enum: LEDGER_TYPES,
        default: 'transaction'
    },
    amount: {
        type: Number,
        required: true
    },
    balanceAfter: {
        type: Number,
        required: true
    },
    transactionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Transaction',
        index: true
    },
    description: {
        type: String,
        trim: true
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed
    },
    createdAt: {
        type: Date,
        default: Date.now,
        immutable: true
    }
});

ledgerEntrySchema.index({ userId: 1, accountId: 1, createdAt: -1 });

module.exports = mongoose.model('LedgerEntry', ledgerEntrySchema);
