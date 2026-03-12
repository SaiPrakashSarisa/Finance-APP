const User = require('../models/User');

const userController = {
    async getSettings(req, res) {
        try {
            const user = await User.findById(req.userId).select('settings');
            if (!user) return res.status(404).json({ success: false, error: 'User not found' });
            res.json({ success: true, data: user.settings });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async updateSettings(req, res) {
        try {
            const { dashboardRange } = req.body;
            const user = await User.findByIdAndUpdate(
                req.userId,
                { $set: { 'settings.dashboardRange': dashboardRange } },
                { new: true, runValidators: true }
            );
            if (!user) return res.status(404).json({ success: false, error: 'User not found' });
            res.json({ success: true, data: user.settings });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    }
};

module.exports = userController;
