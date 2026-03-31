const mongoose = require('mongoose');
const Category = require('../models/Category');

const DEFAULT_CATEGORIES = [
    {
        name: 'Food',
        type: 'expense',
        icon: '🍱',
        color: '#f97316',
        subcategories: [
            { name: 'Groceries', icon: '🛒' },
            { name: 'Dining Out', icon: '🍜' }
        ]
    },
    {
        name: 'Transport',
        type: 'expense',
        icon: '🚗',
        color: '#3b82f6',
        subcategories: [
            { name: 'Fuel', icon: '⛽' },
            { name: 'Public Transport', icon: '🚌' }
        ]
    },
    {
        name: 'Bills',
        type: 'expense',
        icon: '🧾',
        color: '#ef4444',
        subcategories: [
            { name: 'Electricity', icon: '⚡' },
            { name: 'Internet', icon: '🌐' },
            { name: 'Water', icon: '💧' },
            { name: 'Rent', icon: '🏠' }
        ]
    },
    { name: 'Entertainment', type: 'expense', icon: '🎬', color: '#a855f7' },
    { name: 'Health', type: 'expense', icon: '🏥', color: '#10b981' },
    { name: 'Shopping', type: 'expense', icon: '🛍️', color: '#ec4899' },
    { name: 'Others', type: 'expense', icon: '📁', color: '#64748b' },
    { name: 'Salary', type: 'income', icon: '💰', color: '#22c55e' },
    { name: 'Business', type: 'income', icon: '📈', color: '#06b6d4' }
];

async function seedCategories(userId) {
    if (!userId) throw new Error('UserId is required for seeding categories');

    console.log(`🌱 Seeding categories for user: ${userId}`);

    for (const catData of DEFAULT_CATEGORIES) {
        const { subcategories, ...parentData } = catData;
        
        // Check if parent already exists
        let parent = await Category.findOne({ userId, name: parentData.name, type: parentData.type });
        
        if (!parent) {
            parent = await Category.create({ ...parentData, userId });
            console.log(`   + Created Primary: ${parent.name}`);
        } else {
            console.log(`   - Primary exists: ${parent.name}`);
        }

        if (subcategories && subcategories.length > 0) {
            for (const subData of subcategories) {
                const subExists = await Category.findOne({ userId, name: subData.name, parentCategoryId: parent._id });
                if (!subExists) {
                    await Category.create({
                        ...subData,
                        userId,
                        type: parent.type,
                        color: parent.color,
                        parentCategoryId: parent._id
                    });
                     console.log(`     + Created Sub: ${subData.name}`);
                }
            }
        }
    }
    console.log('✅ Seeding completed.');
}

module.exports = seedCategories;
