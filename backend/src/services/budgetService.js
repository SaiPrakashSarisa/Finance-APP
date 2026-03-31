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
        }).select('amount categoryId');

        const summary = budgets.map(budget => {
            const parentId = budget.categoryId._id.toString();
            
            // Find all subcategory IDs for this parent
            const subcategoryIds = allCategories
                .filter(c => c.parentCategoryId && c.parentCategoryId.toString() === parentId)
                .map(c => c._id.toString());
            
            const targetIds = [parentId, ...subcategoryIds];
            
            // Calculate spent amount by summing transactions in these categories
            const spent = transactions
                .filter(tx => tx.categoryId && targetIds.includes(tx.categoryId.toString()))
                .reduce((sum, tx) => sum + tx.amount, 0);

            return {
                _id: budget._id,
                category: budget.categoryId,
                amount: budget.amount,
                spent,
                remaining: budget.amount - spent,
                percentage: budget.amount > 0 ? (spent / budget.amount) * 100 : 0
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
