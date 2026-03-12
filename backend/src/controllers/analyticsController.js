const analyticsService = require('../services/analyticsService');

const analyticsController = {
    async getDashboard(req, res) {
        try {
            const month = req.query.month ? parseInt(req.query.month) : null;
            const year = req.query.year ? parseInt(req.query.year) : null;
            const data = await analyticsService.getDashboard(req.userId, month, year);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getCategoryBreakdown(req, res) {
        try {
            const month = req.query.month ? parseInt(req.query.month) : null;
            const year = req.query.year ? parseInt(req.query.year) : null;
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
            const month = req.query.month ? parseInt(req.query.month) : null;
            const year = req.query.year ? parseInt(req.query.year) : null;
            const data = await analyticsService.getInsights(req.userId, month, year);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = analyticsController;
