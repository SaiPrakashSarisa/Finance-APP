/**
 * Purpose: System Constants and Enums
 * Responsibilities: Holds global constants, transaction types, ledger event types, account types, error codes.
 * Dependencies: None
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 */

module.exports = {
    ACCOUNT_TYPES: ['bank', 'cash', 'credit_card', 'wallet', 'investment', 'loan', 'upi'],
    TRANSACTION_TYPES: [
        'income',
        'expense',
        'transfer',
        'refund',
        'adjustment',
        'credit_repay',
        'credit_given',
        'credit_taken',
        'loan',
        'investment',
        'interest',
        'cash_withdrawal',
        'cash_deposit'
    ],
    LEDGER_TYPES: [
        'opening_balance',
        'transaction',
        'reversal',
        'adjustment',
        'auto_pay'
    ],
    CREDIT_TYPES: ['given', 'taken'],
    CREDIT_SUBTYPES: ['credit', 'debit', 'borrowed', 'lent'],
    LOG_LEVELS: {
        INFO: 'info',
        WARN: 'warn',
        ERROR: 'error',
        AUDIT: 'audit',
        TRANSACTION: 'transaction'
    }
};
