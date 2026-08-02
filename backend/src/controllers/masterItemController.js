const MasterItem = require('../models/MasterItem');

const masterItemController = {
    async lookup(req, res) {
        try {
            const { name } = req.query;
            if (!name) return res.json({ success: true, data: null });
            
            const regex = new RegExp(`^${name.trim()}$`, 'i');
            const item = await MasterItem.findOne({ userId: req.userId, name: regex })
                .populate('defaultCategoryId', 'name color icon parentCategoryId');

            res.json({ success: true, data: item });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
};

module.exports = masterItemController;
