const express = require('express');
const router = express.Router();
const budgetController = require('../controllers/budgetController');

router.get('/', budgetController.getSummary);
router.post('/', budgetController.upsert);
router.delete('/:id', budgetController.delete);

module.exports = router;
