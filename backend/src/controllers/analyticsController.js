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
    },

    async getItemTrends(req, res) {
        try {
            const itemName = req.query.name || req.query.itemName;
            const data = await analyticsService.getItemTrends(req.userId, itemName);
            res.json({ success: true, data });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async getInflationTracker(req, res) {
        try {
            const data = await analyticsService.getInflationTracker(req.userId);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getMerchantAnalytics(req, res) {
        try {
            const data = await analyticsService.getMerchantAnalytics(req.userId);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getMerchantItemComparison(req, res) {
        try {
            const data = await analyticsService.getMerchantItemComparison(req.userId);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getSubscriptions(req, res) {
        try {
            const data = await analyticsService.getSubscriptions(req.userId);
            res.json({ success: true, data });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = analyticsController;
