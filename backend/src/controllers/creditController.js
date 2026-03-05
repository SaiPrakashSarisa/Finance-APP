const creditService = require('../services/creditService');

const creditController = {
    async getAll(req, res) {
        try {
            const filters = {
                type: req.query.type,
                status: req.query.status
            };
            const credits = await creditService.getAll(req.userId, filters);
            res.json({ success: true, data: credits });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getById(req, res) {
        try {
            const credit = await creditService.getById(req.params.id, req.userId);
            if (!credit) return res.status(404).json({ success: false, error: 'Credit not found' });
            res.json({ success: true, data: credit });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async create(req, res) {
        try {
            const data = { ...req.body, userId: req.userId };
            const credit = await creditService.create(data);
            res.status(201).json({ success: true, data: credit });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async update(req, res) {
        try {
            const credit = await creditService.update(req.params.id, req.userId, req.body);
            if (!credit) return res.status(404).json({ success: false, error: 'Credit not found' });
            res.json({ success: true, data: credit });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async getTotals(req, res) {
        try {
            const totals = await creditService.getTotals(req.userId);
            res.json({ success: true, data: totals });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = creditController;
