const express = require('express');
const router = express.Router();
const creditController = require('../controllers/creditController');

router.get('/', creditController.getAll);
router.get('/totals', creditController.getTotals);
router.get('/:id', creditController.getById);
router.post('/', creditController.create);
router.put('/:id', creditController.update);

module.exports = router;
