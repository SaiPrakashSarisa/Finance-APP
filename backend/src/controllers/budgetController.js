const budgetService = require('../services/budgetService');

const budgetController = {
    // Get all budgets for the authenticated user
    async getAll(req, res) {
        try {
            const budgets = await budgetService.getAll(req.userId);
            res.json({ success: true, data: budgets });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    // Create or update a budget
    async upsert(req, res) {
        try {
            const { categoryId, amount, yearMonth } = req.body;
            if (!categoryId || amount === undefined) {
                return res.status(400).json({ success: false, error: 'Category ID and Amount are required' });
            }
            if (amount < 0) {
                return res.status(400).json({ success: false, error: 'Budget amount cannot be negative' });
            }
            const budget = await budgetService.upsert(req.userId, categoryId, amount, yearMonth);
            res.status(200).json({ success: true, data: budget });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    // Delete a budget
    async delete(req, res) {
        try {
            const budget = await budgetService.delete(req.params.id, req.userId);
            if (!budget) return res.status(404).json({ success: false, error: 'Budget not found' });
            res.json({ success: true, data: budget });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    // Get calculated budget progress against real transactions
    async getProgress(req, res) {
        try {
            const month = parseInt(req.query.month) || new Date().getMonth() + 1;
            const year = parseInt(req.query.year) || new Date().getFullYear();
            
            const progress = await budgetService.getProgress(req.userId, month, year);
            res.json({ success: true, data: progress });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    // Get trailing budget performance analytics
    async getAnalytics(req, res) {
        try {
            const now = new Date();
            const fromMonth = parseInt(req.query.fromMonth) || now.getMonth() + 1;
            const fromYear = parseInt(req.query.fromYear) || now.getFullYear() - 1; // Default to trailing 12 months roughly
            const toMonth = parseInt(req.query.toMonth) || now.getMonth() + 1;
            const toYear = parseInt(req.query.toYear) || now.getFullYear();

            const analytics = await budgetService.getAnalytics(req.userId, fromMonth, fromYear, toMonth, toYear);
            res.json({ success: true, data: analytics });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = budgetController;
