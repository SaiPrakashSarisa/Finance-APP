const budgetService = require('../services/budgetService');

const budgetController = {
    async getSummary(req, res) {
        try {
            const { month, year } = req.query;
            const now = new Date();
            const targetMonth = parseInt(month) || now.getMonth() + 1;
            const targetYear = parseInt(year) || now.getFullYear();

            const summary = await budgetService.getSummary(req.userId, targetMonth, targetYear);
            res.json({ success: true, data: summary });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async upsert(req, res) {
        try {
            const { categoryId, amount, month, year } = req.body;
            if (!categoryId || amount === undefined || !month || !year) {
                return res.status(400).json({ success: false, error: 'Missing required fields' });
            }

            const budget = await budgetService.upsert(req.userId, { categoryId, amount, month, year });
            res.json({ success: true, data: budget });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async delete(req, res) {
        try {
            const budget = await budgetService.delete(req.userId, req.params.id);
            if (!budget) return res.status(404).json({ success: false, error: 'Budget not found' });
            res.json({ success: true, message: 'Budget deleted successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = budgetController;
