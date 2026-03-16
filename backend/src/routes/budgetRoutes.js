const express = require('express');
const router = express.Router();
const budgetController = require('../controllers/budgetController');

// All budget routes are protected by authMiddleware (applied in server.js)
router.get('/', budgetController.getAll);
router.post('/upsert', budgetController.upsert);
router.delete('/:id', budgetController.delete);
router.get('/progress', budgetController.getProgress);

module.exports = router;
