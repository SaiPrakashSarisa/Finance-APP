const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');

router.get('/dashboard', analyticsController.getDashboard);
router.get('/categories', analyticsController.getCategoryBreakdown);
router.get('/monthly-trend', analyticsController.getMonthlyTrend);
router.get('/insights', analyticsController.getInsights);

module.exports = router;
