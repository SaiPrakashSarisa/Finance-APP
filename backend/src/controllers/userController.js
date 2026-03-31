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
            const { dashboardRange, budgetEnabled } = req.body;
            const updateFields = {};
            if (dashboardRange !== undefined) updateFields['settings.dashboardRange'] = dashboardRange;
            if (budgetEnabled !== undefined) updateFields['settings.budgetEnabled'] = budgetEnabled;

            const user = await User.findByIdAndUpdate(
                req.userId,
                { $set: updateFields },
                { new: true, runValidators: true }
            );
            if (!user) return res.status(404).json({ success: false, error: 'User not found' });
            res.json({ success: true, data: user.settings });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async getProfile(req, res) {
        try {
            const user = await User.findById(req.userId).select('name email phone countryCode profilePicture');
            if (!user) return res.status(404).json({ success: false, error: 'User not found' });
            res.json({ success: true, data: user });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    async updateProfile(req, res) {
        try {
            const { name, phone, countryCode, profilePicture } = req.body;

            // We do NOT update email here to maintain account integrity unless explicitly required later
            const updateFields = { name, phone, countryCode };
            
            // Only update profile picture if provided (prevents overwriting with null accidentally)
            if (profilePicture !== undefined) {
                updateFields.profilePicture = profilePicture;
            }

            const user = await User.findByIdAndUpdate(
                req.userId,
                { $set: updateFields },
                { new: true, runValidators: true }
            ).select('name email phone countryCode profilePicture settings');

            if (!user) return res.status(404).json({ success: false, error: 'User not found' });
            res.json({ success: true, data: user });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    },

    async changePassword(req, res) {
        try {
            const { currentPassword, newPassword } = req.body;

            if (!currentPassword || !newPassword) {
                return res.status(400).json({ success: false, error: 'Please provide current and new passwords' });
            }

            const user = await User.findById(req.userId).select('+passwordHash');
            if (!user) return res.status(404).json({ success: false, error: 'User not found' });

            const bcrypt = require('bcryptjs'); // Lazy load simply to avoid polluting global scope if unneeded
            
            // Verify current password
            const isMatch = await bcrypt.compare(currentPassword, user.passwordHash);
            if (!isMatch) {
                return res.status(401).json({ success: false, error: 'Incorrect current password' });
            }

            // Hash new password
            const salt = await bcrypt.genSalt(10);
            user.passwordHash = await bcrypt.hash(newPassword, salt);
            await user.save();

            res.json({ success: true, message: 'Password updated successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = userController;
