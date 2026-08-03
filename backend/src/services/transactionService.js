const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const Merchant = require('../models/Merchant');
const MasterItem = require('../models/MasterItem');
const accountService = require('./accountService');
const creditService = require('./creditService');
const { runInTransaction } = require('../utils/dbSession');
const cache = require('../utils/cache');

const transactionService = {
    // Helper to process merchant & master item records
    async _processItemsAndMerchant(data, session = null) {
        if (data.merchantName && data.merchantName.trim()) {
            const trimmedName = data.merchantName.trim();
            const options = { upsert: true, new: true, runValidators: true };
            if (session) options.session = session;
            const merchant = await Merchant.findOneAndUpdate(
                { userId: data.userId, name: trimmedName },
                { $inc: { transactionCount: 1 } },
                options
            );
            if (merchant) data.merchantId = merchant._id;
        }

        if (Array.isArray(data.items) && data.items.length > 0) {
            data.isItemized = true;
            for (const item of data.items) {
                if (item.totalPrice === undefined || item.totalPrice === null) {
                    item.totalPrice = (item.quantity || 1) * (item.unitPrice || 0) - (item.discount || 0);
                }
                if (item.name && item.name.trim()) {
                    const trimmedItem = item.name.trim();
                    const options = { upsert: true, new: true };
                    if (session) options.session = session;
                    const setObj = { lastUnitPrice: item.unitPrice, defaultUnit: item.unit || 'unit' };
                    if (item.categoryId) {
                        setObj.defaultCategoryId = item.categoryId;
                    } else if (data.categoryId) {
                        setObj.defaultCategoryId = data.categoryId;
                    }

                    const master = await MasterItem.findOneAndUpdate(
                        { userId: data.userId, name: trimmedItem },
                        { 
                            $set: setObj,
                            $inc: { purchaseCount: 1 }
                        },
                        options
                    );
                    if (master) item.masterItemId = master._id;
                }
            }
        }
    },

    // Get transactions with filters
    async getAll(userId, filters = {}) {
        const conditions = [{ userId }];

        if (filters.accountId) {
            conditions.push({
                $or: [
                    { accountId: filters.accountId },
                    { toAccountId: filters.accountId }
                ]
            });
        }
        if (filters.type) conditions.push({ type: filters.type });
        if (filters.creditId) conditions.push({ creditId: filters.creditId });
        if (filters.merchantId) conditions.push({ merchantId: filters.merchantId });

        if (filters.categoryId) {
            let catIds = [];
            if (typeof filters.categoryId === 'string' && filters.categoryId.includes(',')) {
                catIds = filters.categoryId.split(',').map(id => id.trim()).filter(Boolean);
            } else if (Array.isArray(filters.categoryId)) {
                catIds = filters.categoryId;
            } else {
                catIds = [filters.categoryId];
            }

            if (catIds.length > 0) {
                conditions.push({
                    $or: [
                        { categoryId: { $in: catIds } },
                        { 'items.categoryId': { $in: catIds } }
                    ]
                });
            }
        }

        if (filters.startDate || filters.endDate) {
            const dateObj = {};
            if (filters.startDate) dateObj.$gte = new Date(filters.startDate);
            if (filters.endDate) dateObj.$lte = new Date(filters.endDate);
            conditions.push({ date: dateObj });
        }

        if (filters.minAmount || filters.maxAmount) {
            const amountObj = {};
            if (filters.minAmount) amountObj.$gte = Number(filters.minAmount);
            if (filters.maxAmount) amountObj.$lte = Number(filters.maxAmount);
            conditions.push({ amount: amountObj });
        }

        const query = conditions.length === 1 ? conditions[0] : { $and: conditions };

        const page = parseInt(filters.page) || 1;
        const limit = parseInt(filters.limit) || 50;
        const skip = (page - 1) * limit;

        const [transactions, total] = await Promise.all([
            Transaction.find(query)
                .populate('accountId', 'name type')
                .populate('toAccountId', 'name type')
                .populate('categoryId', 'name color icon type')
                .populate('creditId', 'personName type subType amount remainingAmount status')
                .populate('merchantId', 'name icon')
                .sort({ date: -1, createdAt: -1 })
                .skip(skip)
                .limit(limit),
            Transaction.countDocuments(query)
        ]);

        return { transactions, total, page, pages: Math.ceil(total / limit) };
    },

    // Get single transaction
    async getById(transactionId, userId) {
        return Transaction.findOne({ _id: transactionId, userId })
            .populate('accountId', 'name type')
            .populate('toAccountId', 'name type')
            .populate('categoryId', 'name color icon type')
            .populate('creditId', 'personName type subType amount remainingAmount status')
            .populate('merchantId', 'name icon');
    },

    // Helper: apply balance effect for a transaction
    async _applyBalanceEffect(tx, multiplier = 1, session = null) {
        const amount = tx.amount * multiplier;
        switch (tx.type) {
            case 'income':
                await accountService.updateBalance(tx.accountId, amount, session);
                break;
            case 'expense':
                await accountService.updateBalance(tx.accountId, -amount, session);
                break;
            case 'transfer':
                await accountService.updateBalance(tx.accountId, -amount, session);
                await accountService.updateBalance(tx.toAccountId, amount, session);
                break;
            case 'credit_repay':
                if (tx.creditId && tx.accountId) {
                    const Credit = require('../models/Credit');
                    const credit = await Credit.findById(typeof tx.creditId === 'object' && tx.creditId._id ? tx.creditId._id : tx.creditId).session(session);
                    if (credit) {
                        if (credit.type === 'given') {
                            // Money coming back to you
                            await accountService.updateBalance(tx.accountId, amount, session);
                        } else {
                            // You're paying back
                            await accountService.updateBalance(tx.accountId, -amount, session);
                        }
                    }
                }
                break;
        }
    },

    // Create transaction and update balance
    async create(data) {
        return runInTransaction(async (session) => {
            // Process Merchant & Items
            await this._processItemsAndMerchant(data, session);

            // Handle credit_repay: validate and apply repayment
            if (data.type === 'credit_repay') {
                if (!data.creditId) throw new Error('Credit entry is required for repayment');
                await creditService.applyRepayment(data.creditId, data.userId, data.amount, session);
            }

            const transaction = new Transaction(data);
            await transaction.save({ session });

            // Apply balance effect
            await this._applyBalanceEffect(transaction, 1, session);

            // Invalidate cache
            cache.clearUserCache(data.userId);

            return Transaction.findById(transaction._id)
                .populate('accountId', 'name type')
                .populate('toAccountId', 'name type')
                .populate('categoryId', 'name color icon type')
                .populate('creditId', 'personName type subType amount remainingAmount status')
                .populate('merchantId', 'name icon')
                .session(session);
        });
    },

    // Update transaction: reverse old balance, apply edits, apply new balance
    async update(transactionId, userId, updates) {
        return runInTransaction(async (session) => {
            const existing = await Transaction.findOne({ _id: transactionId, userId }).session(session);
            if (!existing) throw new Error('Transaction not found');

            // 1. Reverse old balance effect
            await this._applyBalanceEffect(existing, -1, session);

            // 2. Reverse old credit repayment if applicable
            if (existing.type === 'credit_repay' && existing.creditId) {
                await creditService.reverseRepayment(existing.creditId, userId, existing.amount, session);
            }

            // 3. Apply allowed updates
            updates.userId = userId;
            await this._processItemsAndMerchant(updates, session);

            const allowed = ['type', 'amount', 'accountId', 'toAccountId', 'categoryId', 'creditId', 'note', 'date', 'merchantId', 'merchantName', 'isItemized', 'items'];
            allowed.forEach(field => {
                if (updates[field] !== undefined) existing[field] = updates[field];
            });
            if (existing.type !== 'transfer') existing.toAccountId = null;
            if (existing.type === 'transfer') existing.categoryId = null;
            if (existing.type !== 'credit_repay') existing.creditId = null;

            // Recalculate amount if itemized
            if (existing.isItemized && Array.isArray(existing.items) && existing.items.length > 0) {
                const itemSum = existing.items.reduce((sum, item) => sum + (Number(item.totalPrice) || 0), 0);
                if (itemSum > 0) existing.amount = itemSum;
            }

            await existing.save({ session });

            // 4. Apply new credit repayment if applicable
            if (existing.type === 'credit_repay' && existing.creditId) {
                await creditService.applyRepayment(existing.creditId, userId, existing.amount, session);
            }

            // 5. Apply new balance effect
            await this._applyBalanceEffect(existing, 1, session);

            // Invalidate cache
            cache.clearUserCache(userId);

            return Transaction.findById(existing._id)
                .populate('accountId', 'name type')
                .populate('toAccountId', 'name type')
                .populate('categoryId', 'name color icon type')
                .populate('creditId', 'personName type subType amount remainingAmount status')
                .populate('merchantId', 'name icon')
                .session(session);
        });
    },

    // Delete transaction and reverse balance
    async delete(transactionId, userId) {
        return runInTransaction(async (session) => {
            const transaction = await Transaction.findOne({ _id: transactionId, userId }).session(session);
            if (!transaction) throw new Error('Transaction not found');

            // Reverse balance effect
            await this._applyBalanceEffect(transaction, -1, session);

            // Reverse credit repayment if applicable
            if (transaction.type === 'credit_repay' && transaction.creditId) {
                await creditService.reverseRepayment(transaction.creditId, userId, transaction.amount, session);
            }

            await Transaction.deleteOne({ _id: transactionId }, { session });

            // Invalidate cache
            cache.clearUserCache(userId);

            return transaction;
        });
    },

    // Export all user transactions to standard CSV format
    async exportCSV(userId) {
        const transactions = await Transaction.find({ userId })
            .populate('accountId', 'name')
            .populate({
                path: 'categoryId',
                select: 'name parentCategoryId',
                populate: { path: 'parentCategoryId', select: 'name' }
            })
            .sort({ date: -1 });

        const headers = ['Transaction ID', 'Date', 'Type', 'Amount', 'Account', 'Merchant', 'Parent Category', 'Sub Category', 'Note', 'Is Itemized', 'Line Items Summary'];
        
        const rows = transactions.map(t => {
            const dateStr = t.date ? new Date(t.date).toISOString().split('T')[0] : '';
            const accName = t.accountId ? t.accountId.name : '';
            const merchName = t.merchantName || '';
            
            let parentCat = '';
            let subCat = '';
            if (t.categoryId) {
                if (t.categoryId.parentCategoryId) {
                    parentCat = t.categoryId.parentCategoryId.name;
                    subCat = t.categoryId.name;
                } else {
                    parentCat = t.categoryId.name;
                }
            }

            const isItemized = t.isItemized ? 'Yes' : 'No';
            let lineItemsSummary = '';
            if (t.items && t.items.length > 0) {
                lineItemsSummary = t.items.map(i => `${i.name} (${i.quantity}${i.unit || 'unit'} @ ₹${i.unitPrice || 0})`).join('; ');
            }

            const cleanNote = (t.note || '').replace(/"/g, '""');

            return [
                t._id,
                dateStr,
                t.type,
                t.amount,
                `"${accName.replace(/"/g, '""')}"`,
                `"${merchName.replace(/"/g, '""')}"`,
                `"${parentCat.replace(/"/g, '""')}"`,
                `"${subCat.replace(/"/g, '""')}"`,
                `"${cleanNote}"`,
                isItemized,
                `"${lineItemsSummary.replace(/"/g, '""')}"`
            ].join(',');
        });

        return [headers.join(','), ...rows].join('\n');
    },

    // Import transactions from CSV backup and restore clean state
    async importCSV(userId, csvText, mode = 'replace') {
        const Account = require('../models/Account');
        const Category = require('../models/Category');

        const parseCSVLines = (text) => {
            const lines = [];
            let curLine = '';
            let inQuotes = false;
            for (let i = 0; i < text.length; i++) {
                const char = text[i];
                if (char === '"') {
                    inQuotes = !inQuotes;
                    curLine += char;
                } else if ((char === '\n' || char === '\r') && !inQuotes) {
                    if (curLine.trim()) lines.push(curLine.trim());
                    curLine = '';
                    if (char === '\r' && text[i + 1] === '\n') i++;
                } else {
                    curLine += char;
                }
            }
            if (curLine.trim()) lines.push(curLine.trim());
            return lines;
        };

        const parseCSVRow = (line) => {
            const result = [];
            let curCell = '';
            let inQuotes = false;
            for (let i = 0; i < line.length; i++) {
                const char = line[i];
                if (char === '"') {
                    if (inQuotes && line[i + 1] === '"') {
                        curCell += '"';
                        i++;
                    } else {
                        inQuotes = !inQuotes;
                    }
                } else if (char === ',' && !inQuotes) {
                    result.push(curCell.trim());
                    curCell = '';
                } else {
                    curCell += char;
                }
            }
            result.push(curCell.trim());
            return result;
        };

        const lines = parseCSVLines(csvText);
        if (lines.length < 2) throw new Error('Invalid or empty CSV file');

        const headerRow = parseCSVRow(lines[0]).map(h => h.toLowerCase());
        
        const dateIdx = headerRow.findIndex(h => h.includes('date'));
        const typeIdx = headerRow.findIndex(h => h.includes('type'));
        const amountIdx = headerRow.findIndex(h => h.includes('amount'));
        const accountIdx = headerRow.findIndex(h => h.includes('account'));
        const merchIdx = headerRow.findIndex(h => h.includes('merchant'));
        const parentCatIdx = headerRow.findIndex(h => h.includes('parent category') || h === 'category');
        const subCatIdx = headerRow.findIndex(h => h.includes('sub category'));
        const noteIdx = headerRow.findIndex(h => h.includes('note'));
        const itemsIdx = headerRow.findIndex(h => h.includes('line items') || h.includes('items'));

        if (dateIdx === -1 || amountIdx === -1) {
            throw new Error('CSV missing required headers: Date and Amount');
        }

        // If mode === 'replace', clean existing transactions & reset balances to initialBalance
        if (mode === 'replace') {
            await Transaction.deleteMany({ userId });
            const existingAccs = await Account.find({ userId });
            for (const acc of existingAccs) {
                acc.balance = Number(acc.initialBalance) || 0;
                await acc.save();
            }
        }

        const userAccounts = await Account.find({ userId });
        const accountMap = new Map();
        userAccounts.forEach(a => accountMap.set(a.name.toLowerCase(), a));

        const userCategories = await Category.find({ userId });
        const categoryMap = new Map();
        userCategories.forEach(c => categoryMap.set(c.name.toLowerCase(), c));

        let createdCount = 0;

        for (let i = 1; i < lines.length; i++) {
            const row = parseCSVRow(lines[i]);
            if (row.length === 0 || !row[amountIdx]) continue;

            const dateStr = row[dateIdx] || new Date().toISOString();
            const typeStr = (row[typeIdx] || 'expense').toLowerCase();
            const amountVal = Math.abs(parseFloat(row[amountIdx])) || 0;
            const accountName = row[accountIdx] || 'Default Account';
            const merchName = merchIdx !== -1 ? row[merchIdx] : '';
            const parentCatName = parentCatIdx !== -1 ? row[parentCatIdx] : '';
            const subCatName = subCatIdx !== -1 ? row[subCatIdx] : '';
            const noteStr = noteIdx !== -1 ? row[noteIdx] : '';
            const itemsStr = itemsIdx !== -1 ? row[itemsIdx] : '';

            // Match or create Account
            let account = accountMap.get(accountName.toLowerCase());
            if (!account) {
                account = await Account.create({
                    userId,
                    name: accountName,
                    type: 'savings',
                    balance: 0
                });
                accountMap.set(accountName.toLowerCase(), account);
            }

            // Match or create Category (Parent & Subcategory)
            let parentCategory = null;
            if (parentCatName) {
                parentCategory = categoryMap.get(parentCatName.toLowerCase());
                if (!parentCategory) {
                    parentCategory = await Category.create({
                        userId,
                        name: parentCatName,
                        type: typeStr === 'income' ? 'income' : 'expense',
                        color: '#6366f1'
                    });
                    categoryMap.set(parentCatName.toLowerCase(), parentCategory);
                }
            }

            let targetCategory = null;
            if (subCatName) {
                targetCategory = categoryMap.get(subCatName.toLowerCase());
                if (!targetCategory) {
                    targetCategory = await Category.create({
                        userId,
                        name: subCatName,
                        type: typeStr === 'income' ? 'income' : 'expense',
                        color: '#6366f1',
                        parentCategoryId: parentCategory ? parentCategory._id : undefined
                    });
                    categoryMap.set(subCatName.toLowerCase(), targetCategory);
                }
            } else if (parentCategory) {
                targetCategory = parentCategory;
            }

            // Parse items summary if itemized
            const parsedItems = [];
            if (itemsStr) {
                const parts = itemsStr.split(';');
                for (const part of parts) {
                    const trimmed = part.trim();
                    if (!trimmed) continue;
                    const match = trimmed.match(/^(.+?)\s*\(([\d.]+)([a-zA-Z]+)?\s*@\s*₹?([\d.]+)\)$/);
                    if (match) {
                        parsedItems.push({
                            name: match[1].trim(),
                            quantity: parseFloat(match[2]) || 1,
                            unit: match[3] || 'unit',
                            unitPrice: parseFloat(match[4]) || 0,
                            totalPrice: (parseFloat(match[2]) || 1) * (parseFloat(match[4]) || 0)
                        });
                    } else {
                        parsedItems.push({ name: trimmed, quantity: 1, unit: 'unit', unitPrice: amountVal, totalPrice: amountVal });
                    }
                }
            }

            const txData = {
                userId,
                accountId: account._id,
                type: ['income', 'expense', 'transfer', 'credit_repay'].includes(typeStr) ? typeStr : 'expense',
                amount: amountVal,
                categoryId: targetCategory ? targetCategory._id : null,
                merchantName: merchName || undefined,
                note: noteStr || undefined,
                isItemized: parsedItems.length > 0,
                items: parsedItems,
                date: new Date(dateStr)
            };

            await this.create(txData);
            createdCount++;
        }

        cache.clearUserCache(userId);

        return { success: true, count: createdCount, message: `Successfully restored ${createdCount} transactions from CSV backup` };
    }
};

module.exports = transactionService;
