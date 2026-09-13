const Category = require('../models/Category');
const mongoose = require('mongoose');

const defaultCategorySeeds = [
    {
        name: 'Food & Dining', type: 'expense', icon: 'restaurant', color: '#10B981',
        subs: ['Groceries & Supermarket', 'Restaurants & Fast Food', 'Cafes & Coffee Shops', 'Food Delivery']
    },
    {
        name: 'Transportation', type: 'expense', icon: 'directions_car', color: '#F59E0B',
        subs: ['Fuel & Gas', 'Cabs & Ride Share', 'Public Transit & Metro', 'Vehicle Service & Parking']
    },
    {
        name: 'Housing & Utilities', type: 'expense', icon: 'home', color: '#6366F1',
        subs: ['Rent & Mortgage', 'Electricity & Water', 'Internet & Wi-Fi', 'Home Maintenance']
    },
    {
        name: 'Shopping & Lifestyle', type: 'expense', icon: 'shopping_cart', color: '#EC4899',
        subs: ['Clothing & Apparel', 'Electronics & Gadgets', 'Beauty & Personal Care', 'Gifts & Celebrations']
    },
    {
        name: 'Entertainment', type: 'expense', icon: 'movie', color: '#8B5CF6',
        subs: ['Movies & Events', 'Subscriptions', 'Gaming & Apps', 'Outings & Hobbies']
    },
    {
        name: 'Health & Wellness', type: 'expense', icon: 'medical_services', color: '#EF4444',
        subs: ['Medicines & Pharmacy', 'Doctor Consultations & Labs', 'Gym & Fitness', 'Health Insurance']
    },
    {
        name: 'Education', type: 'expense', icon: 'school', color: '#06B6D4',
        subs: ['Tuition & School Fees', 'Books & Stationery', 'Courses & Certifications']
    },
    {
        name: 'Travel & Vacations', type: 'expense', icon: 'flight', color: '#3B82F6',
        subs: ['Flights & Trains', 'Hotels & Accommodation', 'Sightseeing & Tours']
    },
    {
        name: 'Financial Obligations', type: 'expense', icon: 'credit_card', color: '#64748B',
        subs: ['Loan EMI / Interest', 'Credit Card Repayment', 'Taxes & Bank Fees']
    },
    {
        name: 'Salary & Wages', type: 'income', icon: 'work', color: '#059669',
        subs: ['Monthly Salary', 'Bonus & Commission', 'Overtime Pay']
    },
    {
        name: 'Business & Freelance', type: 'income', icon: 'trending_up', color: '#4F46E5',
        subs: ['Freelance Projects', 'Business Revenue', 'Consulting & Services']
    },
    {
        name: 'Investments & Capital', type: 'income', icon: 'attach_money', color: '#0891B2',
        subs: ['Dividends & Stock Profits', 'Bank Interest', 'Mutual Fund Returns']
    },
    {
        name: 'Rental & Passive', type: 'income', icon: 'home', color: '#0D9488',
        subs: ['Property Rent Received', 'Royalties & Licensing']
    },
    {
        name: 'Other Income', type: 'income', icon: 'redeem', color: '#7C3AED',
        subs: ['Gifts & Allowances', 'Refunds & Cashback']
    }
];

const seedingLocks = new Set();

async function autoSeedCategories(userId) {
    if (!userId) return;
    const userIdStr = userId.toString();

    // If another request is currently seeding categories for this user, wait for it to complete
    if (seedingLocks.has(userIdStr)) {
        while (seedingLocks.has(userIdStr)) {
            await new Promise(resolve => setTimeout(resolve, 50));
        }
        return;
    }

    seedingLocks.add(userIdStr);
    try {
        const existingCount = await Category.countDocuments({ userId });
        if (existingCount > 0) {
            return;
        }

        for (const item of defaultCategorySeeds) {
            let parent = await Category.findOne({ userId, name: item.name, type: item.type, parentCategoryId: null });
            if (!parent) {
                try {
                    parent = await Category.create({
                        userId,
                        name: item.name,
                        type: item.type,
                        icon: item.icon,
                        color: item.color,
                        parentCategoryId: null
                    });
                } catch (err) {
                    parent = await Category.findOne({ userId, name: item.name, type: item.type, parentCategoryId: null });
                }
            }

            if (!parent) continue;

            for (const subName of item.subs) {
                const existingSub = await Category.findOne({ userId, name: subName, type: item.type, parentCategoryId: parent._id });
                if (!existingSub) {
                    try {
                        await Category.create({
                            userId,
                            name: subName,
                            type: item.type,
                            icon: item.icon,
                            color: item.color,
                            parentCategoryId: parent._id
                        });
                    } catch (err) {
                        // Ignore duplicate key error gracefully
                    }
                }
            }
        }
    } catch (err) {
        console.error('Category auto-seed failed:', err.message);
    } finally {
        seedingLocks.delete(userIdStr);
    }
}

const categoryController = {
    seedUserDefaultCategories: autoSeedCategories,

    async getAll(req, res) {
        try {
            let categories = await Category.find({ userId: req.userId });
            if (categories.length === 0) {
                await autoSeedCategories(req.userId);
                categories = await Category.find({ userId: req.userId });
            }

            const filter = { userId: req.userId };
            if (req.query.type) filter.type = req.query.type;
            
            categories = await Category.find(filter);
            
            // Organize into hierarchical tree order: Parent followed immediately by its subcategories
            const parents = categories.filter(c => !c.parentCategoryId).sort((a, b) => a.name.localeCompare(b.name));
            const organized = [];
            for (const p of parents) {
                organized.push(p);
                const children = categories
                    .filter(c => c.parentCategoryId && c.parentCategoryId.toString() === p._id.toString())
                    .sort((a, b) => a.name.localeCompare(b.name));
                organized.push(...children);
            }
            const addedIds = new Set(organized.map(c => c._id.toString()));
            const remaining = categories.filter(c => !addedIds.has(c._id.toString()));
            organized.push(...remaining);

            if (req.query.tree === 'true') {
                const parentsList = categories.filter(c => !c.parentCategoryId);
                const result = parentsList.map(p => {
                    const children = categories.filter(c => c.parentCategoryId && c.parentCategoryId.toString() === p._id.toString());
                    return {
                        ...p._doc,
                        subcategories: children
                    };
                });
                return res.json({ success: true, data: result });
            }

            res.json({ success: true, data: organized });
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
    }
};

module.exports = categoryController;
