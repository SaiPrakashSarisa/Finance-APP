const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');

router.get('/', categoryController.getAll);
router.post('/seed-standard', categoryController.seedStandardTaxonomy);
router.post('/migrate', categoryController.migrateCategories);
router.post('/', categoryController.create);
router.put('/:id', categoryController.update);
router.delete('/:id', categoryController.delete);

module.exports = router;
