const mongoose = require('mongoose');
const Budget = require('../models/Budget');
const Category = require('../models/Category');
const Transaction = require('../models/Transaction');

const budgetService = {
    async getSummary(userId, month, year) {
        // Fetch all budgets for the month
        const budgets = await Budget.find({ userId, month, year })
            .populate('categoryId', 'name color icon');
        
        // Fetch all categories to identify subcategories
        const allCategories = await Category.find({ userId });
        
        // Prepare date range
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0, 23, 59, 59, 999);

        // Fetch all expense transactions for the month in one go (optimization)
        const transactions = await Transaction.find({
            userId,
            type: 'expense',
            date: { $gte: startDate, $lte: endDate }
        }).select('amount categoryId isItemized items');

        // Build spending map per category ID (supporting line-item level category assignments)
        const categorySpendingMap = {};
        transactions.forEach(tx => {
            if (tx.isItemized && Array.isArray(tx.items) && tx.items.length > 0) {
                tx.items.forEach(item => {
                    const catId = item.categoryId ? item.categoryId.toString() : (tx.categoryId ? tx.categoryId.toString() : null);
                    if (catId) {
                        const itemAmount = item.totalPrice !== undefined && item.totalPrice !== null 
                            ? item.totalPrice 
                            : ((item.quantity || 1) * (item.unitPrice || 0));
                        categorySpendingMap[catId] = (categorySpendingMap[catId] || 0) + itemAmount;
                    }
                });
            } else if (tx.categoryId) {
                const catId = tx.categoryId.toString();
                categorySpendingMap[catId] = (categorySpendingMap[catId] || 0) + tx.amount;
            }
        });

        const summary = budgets.map(budget => {
            const parentId = budget.categoryId._id.toString();
            
            // Find all subcategories for this parent
            const subcategories = allCategories
                .filter(c => c.parentCategoryId && c.parentCategoryId.toString() === parentId);
            
            const subcategoryIds = subcategories.map(c => c._id.toString());
            const targetIds = [parentId, ...subcategoryIds];
            
            // Calculate parent direct spent
            const directParentSpent = categorySpendingMap[parentId] || 0;

            // Calculate per-subcategory spent breakdown
            const subcategoryBreakdown = subcategories.map(sub => {
                const subSpent = categorySpendingMap[sub._id.toString()] || 0;
                
                return {
                    _id: sub._id,
                    name: sub.name,
                    icon: sub.icon,
                    color: sub.color,
                    spent: subSpent,
                    percentage: budget.amount > 0 ? Math.round((subSpent / budget.amount) * 100 * 10) / 10 : 0
                };
            });

            // If there's direct parent spending not in a subcategory, add an entry for it
            if (directParentSpent > 0) {
                subcategoryBreakdown.unshift({
                    _id: parentId,
                    name: `${budget.categoryId.name} (General)`,
                    icon: budget.categoryId.icon,
                    color: budget.categoryId.color,
                    spent: directParentSpent,
                    percentage: budget.amount > 0 ? Math.round((directParentSpent / budget.amount) * 100 * 10) / 10 : 0
                });
            }

            // Calculate total spent amount across parent and subcategories
            const spent = targetIds.reduce((sum, id) => sum + (categorySpendingMap[id] || 0), 0);

            return {
                _id: budget._id,
                category: budget.categoryId,
                amount: budget.amount,
                spent,
                remaining: budget.amount - spent,
                percentage: budget.amount > 0 ? Math.round((spent / budget.amount) * 100 * 10) / 10 : 0,
                subcategories: subcategoryBreakdown
            };
        });

        return summary;
    },

    async upsert(userId, data) {
        const { categoryId, amount, month, year } = data;
        
        // Validate category is top-level
        const category = await Category.findOne({ _id: categoryId, userId });
        if (!category) throw new Error('Category not found');
        if (category.parentCategoryId) throw new Error('Budgets can only be set on top-level categories');

        return Budget.findOneAndUpdate(
            { userId, categoryId, month, year },
            { amount },
            { upsert: true, new: true, runValidators: true }
        );
    },

    async delete(userId, budgetId) {
        return Budget.findOneAndDelete({ _id: budgetId, userId });
    }
};

module.exports = budgetService;
