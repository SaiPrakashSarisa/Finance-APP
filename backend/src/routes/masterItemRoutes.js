const express = require('express');
const router = express.Router();
const masterItemController = require('../controllers/masterItemController');

router.get('/lookup', masterItemController.lookup);

module.exports = router;
