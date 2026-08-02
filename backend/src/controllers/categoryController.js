const Category = require('../models/Category');
const mongoose = require('mongoose');

const categoryController = {
    async getAll(req, res) {
        try {
            const filter = { userId: req.userId };
            if (req.query.type) filter.type = req.query.type;
            
            const categories = await Category.find(filter).sort({ name: 1 });
            
            if (req.query.tree === 'true') {
                // Return hierarchical structure
                const parents = categories.filter(c => !c.parentCategoryId);
                const result = parents.map(p => {
                    const children = categories.filter(c => c.parentCategoryId && c.parentCategoryId.toString() === p._id.toString());
                    return {
                        ...p._doc,
                        subcategories: children
                    };
                });
                return res.json({ success: true, data: result });
            }

            res.json({ success: true, data: categories });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async create(req, res) {
        try {
            const { name, type, color, icon, parentCategoryId } = req.body;
            
            const data = { name, type, color, icon, userId: req.userId };
            
            if (parentCategoryId) {
                // Validate parent
                const parent = await Category.findOne({ _id: parentCategoryId, userId: req.userId });
                if (!parent) return res.status(404).json({ success: false, error: 'Parent category not found' });
                if (parent.parentCategoryId) return res.status(400).json({ success: false, error: 'Only two levels of categories are allowed' });
                
                data.parentCategoryId = parentCategoryId;
                data.type = parent.type; // Force sub-category to have same type as parent
            }

            const category = await Category.create(data);
            res.status(201).json({ success: true, data: category });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async update(req, res) {
        try {
            const allowed = ['name', 'color', 'icon', 'parentCategoryId'];
            const updates = {};
            allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

            if (updates.parentCategoryId) {
                const parent = await Category.findOne({ _id: updates.parentCategoryId, userId: req.userId });
                if (!parent) return res.status(404).json({ success: false, error: 'Parent category not found' });
                if (parent.parentCategoryId) return res.status(400).json({ success: false, error: 'Only two levels of categories are allowed' });
            }

            const category = await Category.findOneAndUpdate(
                { _id: req.params.id, userId: req.userId },
                updates,
                { new: true, runValidators: true }
            );
            if (!category) return res.status(404).json({ success: false, error: 'Category not found' });
            res.json({ success: true, data: category });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async delete(req, res) {
        try {
            const category = await Category.findOne({ _id: req.params.id, userId: req.userId });
            if (!category) return res.status(404).json({ success: false, error: 'Category not found' });

            // If it's a primary category, delete all subcategories too
            if (!category.parentCategoryId) {
                await Category.deleteMany({ parentCategoryId: category._id, userId: req.userId });
            }

            await Category.findByIdAndDelete(category._id);
            res.json({ success: true, message: 'Category deleted successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async seedStandardTaxonomy(req, res) {
        try {
            const userId = req.userId;
            const Transaction = require('../models/Transaction');
            
            const STANDARD_TAXONOMY = [
                {
                    name: 'Food & Groceries', type: 'expense', color: '#f43f5e', icon: '🛒',
                    subcategories: [
                        { name: 'Supermarket & Groceries', icon: '🥬' },
                        { name: 'Restaurants & Dining Out', icon: '🍕' },
                        { name: 'Coffee & Snacks', icon: '☕' }
                    ]
                },
                {
                    name: 'Housing & Utilities', type: 'expense', color: '#6366f1', icon: '🏠',
                    subcategories: [
                        { name: 'House Rent', icon: '🔑' },
                        { name: 'Electricity & Gas', icon: '⚡' },
                        { name: 'WiFi & Broadband', icon: '📶' }
                    ]
                },
                {
                    name: 'Transportation', type: 'expense', color: '#f59e0b', icon: '🚗',
                    subcategories: [
                        { name: 'Petrol & Fuel', icon: '⛽' },
                        { name: 'Uber & Cab Booking', icon: '🚕' }
                    ]
                },
                {
                    name: 'Personal Care & Grooming', type: 'expense', color: '#a855f7', icon: '✂️',
                    subcategories: [
                        { name: 'Haircut & Salon', icon: '✂️' },
                        { name: 'Skincare & Cosmetics', icon: '🧴' }
                    ]
                },
                {
                    name: 'Giving & Charity', type: 'expense', color: '#06b6d4', icon: '🤝',
                    subcategories: [
                        { name: 'Helping Needy & Street Charity', icon: '🤝' },
                        { name: 'Donations & Tipping', icon: '🎁' }
                    ]
                },
                {
                    name: 'Shopping & Apparel', type: 'expense', color: '#ec4899', icon: '🛍️',
                    subcategories: [
                        { name: 'Clothing & Footwear', icon: '👕' }
                    ]
                },
                {
                    name: 'Miscellaneous & Adjustments', type: 'expense', color: '#94a3b8', icon: '❓',
                    subcategories: [
                        { name: 'Unaccounted / Forgot Spent', icon: '❓' },
                        { name: 'Cash Balance Adjustment', icon: '⚖️' }
                    ]
                },
                {
                    name: 'Salary & Earnings', type: 'income', color: '#10b981', icon: '💰',
                    subcategories: [
                        { name: 'Primary Salary', icon: '💵' },
                        { name: 'Freelance & Consulting', icon: '💻' }
                    ]
                },
                {
                    name: 'Investments', type: 'income', color: '#8b5cf6', icon: '📈',
                    subcategories: [
                        { name: 'Stock Dividends', icon: '📊' }
                    ]
                }
            ];

            const created = [];
            for (const cat of STANDARD_TAXONOMY) {
                let parent = await Category.findOne({ userId, name: cat.name, parentCategoryId: null });
                if (!parent) {
                    parent = await Category.create({
                        userId, name: cat.name, type: cat.type, color: cat.color, icon: cat.icon
                    });
                }
                created.push(parent);

                for (const sub of cat.subcategories) {
                    let child = await Category.findOne({ userId, name: sub.name, parentCategoryId: parent._id });
                    if (!child) {
                        child = await Category.create({
                            userId, name: sub.name, type: cat.type, color: cat.color, icon: sub.icon, parentCategoryId: parent._id
                        });
                    }
                    created.push(child);
                }
            }

            res.json({ success: true, message: 'Standard categories taxonomy generated successfully', count: created.length });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async migrateCategories(req, res) {
        try {
            const userId = req.userId;
            const { mappings, purgeOld } = req.body;
            const Transaction = require('../models/Transaction');
            const cache = require('../utils/cache');

            if (!mappings || !Array.isArray(mappings)) {
                return res.status(400).json({ success: false, error: 'mappings array is required' });
            }

            let updatedCount = 0;
            const oldIdsToDelete = [];

            for (const item of mappings) {
                const { oldCategoryId, newCategoryId } = item;
                if (!oldCategoryId || !newCategoryId) continue;

                const result = await Transaction.updateMany(
                    { userId, categoryId: oldCategoryId },
                    { $set: { categoryId: newCategoryId } }
                );

                updatedCount += result.modifiedCount;
                oldIdsToDelete.push(oldCategoryId);
            }

            if (purgeOld && oldIdsToDelete.length > 0) {
                await Category.deleteMany({ userId, _id: { $in: oldIdsToDelete } });
            }

            cache.clearUserCache(userId);

            res.json({
                success: true,
                message: `Successfully migrated ${updatedCount} transactions to standard categories`,
                updatedTransactions: updatedCount,
                purgedCategories: purgeOld ? oldIdsToDelete.length : 0
            });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = categoryController;
