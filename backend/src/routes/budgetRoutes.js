const express = require('express');
const router = express.Router();
const budgetController = require('../controllers/budgetController');

// All budget routes are protected by authMiddleware (applied in server.js)
router.get('/', budgetController.getAll);
router.post('/upsert', budgetController.upsert);
router.get('/analytics', budgetController.getAnalytics);
router.get('/progress', budgetController.getProgress);
router.delete('/:id', budgetController.delete);

module.exports = router;
