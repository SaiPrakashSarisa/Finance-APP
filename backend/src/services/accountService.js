/**
 * Purpose: Account Service Layer
 * Responsibilities: Handles business rules for account creation, balance synchronization, and ledger updates.
 * Dependencies: AccountRepository, LedgerRepository, runInTransaction, logger
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 * Business Rules:
 *  - Opening balance creates an immutable 'opening_balance' LedgerEntry (not an income transaction).
 *  - Balance changes must generate a traceable LedgerEntry inside an atomic database session.
 *  - Supports balance reconstruction from ledger entries.
 */

const accountRepository = require('../repositories/AccountRepository');
const ledgerRepository = require('../repositories/LedgerRepository');
const { runInTransaction } = require('../utils/dbSession');
const logger = require('../utils/logger');

const accountService = {
    async getAll(userId) {
        return accountRepository.findAll(userId);
    },

    async getById(accountId, userId) {
        return accountRepository.findById(accountId, userId);
    },

    async create(data) {
        return runInTransaction(async (session) => {
            const initialBal = Number(data.initialBalance !== undefined ? data.initialBalance : (data.balance || 0));
            data.initialBalance = initialBal;
            data.balance = initialBal;

            const account = await accountRepository.create(data, session);

            // Create immutable opening balance ledger entry
            if (initialBal !== 0) {
                await ledgerRepository.create({
                    userId: data.userId,
                    accountId: account._id,
                    type: 'opening_balance',
                    amount: initialBal,
                    balanceAfter: initialBal,
                    description: `Initial Opening Balance for ${account.name}`
                }, session);
            }

            logger.audit('Account Created', { userId: data.userId, accountId: account._id, name: account.name, initialBalance: initialBal });
            return account;
        });
    },

    async update(accountId, userId, data) {
        const allowed = ['name', 'type', 'currency', 'isActive'];
        const updates = {};
        allowed.forEach(field => {
            if (data[field] !== undefined) updates[field] = data[field];
        });
        return accountRepository.update(accountId, userId, updates);
    },

    async delete(accountId, userId) {
        return accountRepository.update(accountId, userId, { isActive: false });
    },

    async updateBalance(accountId, amount, session = null, allowNegative = true, ledgerMeta = {}) {
        const account = await accountRepository.updateBalance(accountId, amount, session);
        if (!account) throw new Error('Account not found for balance update');

        if (!allowNegative && account.type !== 'credit_card' && account.balance < 0) {
            throw new Error(`Insufficient balance in account: ${account.name}`);
        }

        // Record immutable ledger entry
        if (ledgerMeta.userId) {
            await ledgerRepository.create({
                userId: ledgerMeta.userId,
                accountId: account._id,
                type: ledgerMeta.type || 'transaction',
                amount: amount,
                balanceAfter: account.balance,
                transactionId: ledgerMeta.transactionId || undefined,
                description: ledgerMeta.description || 'Balance Update'
            }, session);
        }

        logger.transaction('Account Balance Updated', { accountId, amount, newBalance: account.balance });
        return account;
    },

    /**
     * Authoritative ledger balance recovery: Rebuilds account balance from sum of ledger entries
     */
    async rebuildBalanceFromLedger(accountId, userId) {
        return runInTransaction(async (session) => {
            const derivedBalance = await ledgerRepository.calculateDerivedBalance(accountId, userId);
            const account = await accountRepository.update(accountId, userId, { balance: derivedBalance }, session);
            logger.audit('Account Balance Rebuilt From Ledger', { accountId, userId, derivedBalance });
            return account;
        });
    }
};

module.exports = accountService;
