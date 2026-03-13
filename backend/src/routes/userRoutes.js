const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.get('/settings', userController.getSettings);
router.patch('/settings', userController.updateSettings);

module.exports = router;
