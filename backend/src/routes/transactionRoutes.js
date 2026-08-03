const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transactionController');

router.get('/', transactionController.getAll);
router.get('/export/csv', transactionController.exportCSV);
router.post('/import/csv', transactionController.importCSV);
router.get('/:id', transactionController.getById);
router.post('/', transactionController.create);
router.put('/:id', transactionController.update);
router.delete('/:id', transactionController.delete);

module.exports = router;
