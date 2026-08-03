const transactionService = require('../services/transactionService');

const transactionController = {
    async getAll(req, res) {
        try {
            const filters = {
                accountId: req.query.accountId,
                type: req.query.type,
                categoryId: req.query.categoryId,
                creditId: req.query.creditId,
                startDate: req.query.startDate,
                endDate: req.query.endDate,
                minAmount: req.query.minAmount,
                maxAmount: req.query.maxAmount,
                page: req.query.page,
                limit: req.query.limit
            };
            const result = await transactionService.getAll(req.userId, filters);
            res.json({ success: true, ...result });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getById(req, res) {
        try {
            const transaction = await transactionService.getById(req.params.id, req.userId);
            if (!transaction) return res.status(404).json({ success: false, error: 'Transaction not found' });
            res.json({ success: true, data: transaction });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async create(req, res) {
        try {
            const data = { ...req.body, userId: req.userId };
            const transaction = await transactionService.create(data);
            res.status(201).json({ success: true, data: transaction });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async update(req, res) {
        try {
            const transaction = await transactionService.update(req.params.id, req.userId, req.body);
            res.json({ success: true, data: transaction });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async delete(req, res) {
        try {
            const transaction = await transactionService.delete(req.params.id, req.userId);
            res.json({ success: true, data: transaction });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async exportCSV(req, res) {
        try {
            const csv = await transactionService.exportCSV(req.userId);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename="transactions_export.csv"');
            res.status(200).send(csv);
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async importCSV(req, res) {
        try {
            const { csvText, mode } = req.body;
            if (!csvText) return res.status(400).json({ success: false, error: 'csvText is required' });
            const result = await transactionService.importCSV(req.userId, csvText, mode || 'replace');
            res.json(result);
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = transactionController;
