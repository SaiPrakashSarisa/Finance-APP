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
    }
};

module.exports = categoryController;
