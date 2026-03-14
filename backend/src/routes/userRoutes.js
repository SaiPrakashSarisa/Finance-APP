const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.get('/settings', userController.getSettings);
router.patch('/settings', userController.updateSettings);

router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);
router.put('/change-password', userController.changePassword);

module.exports = router;
