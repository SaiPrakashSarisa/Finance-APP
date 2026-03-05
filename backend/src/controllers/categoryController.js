const Category = require('../models/Category');

const categoryController = {
    async getAll(req, res) {
        try {
            const filter = { userId: req.userId };
            if (req.query.type) filter.type = req.query.type;
            const categories = await Category.find(filter).sort({ name: 1 });
            res.json({ success: true, data: categories });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async create(req, res) {
        try {
            const data = { ...req.body, userId: req.userId };
            const category = await Category.create(data);
            res.status(201).json({ success: true, data: category });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async update(req, res) {
        try {
            const allowed = ['name', 'type', 'color', 'icon'];
            const updates = {};
            allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

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
            const category = await Category.findOneAndDelete({ _id: req.params.id, userId: req.userId });
            if (!category) return res.status(404).json({ success: false, error: 'Category not found' });
            res.json({ success: true, data: category });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = categoryController;
