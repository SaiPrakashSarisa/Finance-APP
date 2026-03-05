const analyticsService = require('../services/analyticsService');

const analyticsController = {
    async getDashboard(req, res) {
        try {
            const month = parseInt(req.query.month) || new Date().getMonth() + 1;
            const year = parseInt(req.query.year) || new Date().getFullYear();
            const data = await analyticsService.getDashboard(req.userId, month, year);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getCategoryBreakdown(req, res) {
        try {
            const month = parseInt(req.query.month) || new Date().getMonth() + 1;
            const year = parseInt(req.query.year) || new Date().getFullYear();
            const data = await analyticsService.getCategoryBreakdown(req.userId, month, year);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getMonthlyTrend(req, res) {
        try {
            const data = await analyticsService.getMonthlyTrend(req.userId);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getInsights(req, res) {
        try {
            const data = await analyticsService.getInsights(req.userId);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = analyticsController;
