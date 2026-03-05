const accountService = require('../services/accountService');

const accountController = {
    async getAll(req, res) {
        try {
            const accounts = await accountService.getAll(req.userId);
            res.json({ success: true, data: accounts });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async getById(req, res) {
        try {
            const account = await accountService.getById(req.params.id, req.userId);
            if (!account) return res.status(404).json({ success: false, error: 'Account not found' });
            res.json({ success: true, data: account });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async create(req, res) {
        try {
            const data = { ...req.body, userId: req.userId };
            const account = await accountService.create(data);
            res.status(201).json({ success: true, data: account });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async update(req, res) {
        try {
            const account = await accountService.update(req.params.id, req.userId, req.body);
            if (!account) return res.status(404).json({ success: false, error: 'Account not found' });
            res.json({ success: true, data: account });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async delete(req, res) {
        try {
            const account = await accountService.delete(req.params.id, req.userId);
            if (!account) return res.status(404).json({ success: false, error: 'Account not found' });
            res.json({ success: true, data: account });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = accountController;
