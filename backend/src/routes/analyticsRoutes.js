const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');

router.get('/dashboard', analyticsController.getDashboard);
router.get('/categories', analyticsController.getCategoryBreakdown);
router.get('/monthly-trend', analyticsController.getMonthlyTrend);
router.get('/insights', analyticsController.getInsights);
router.get('/items/trends', analyticsController.getItemTrends);
router.get('/inflation', analyticsController.getInflationTracker);
router.get('/merchants', analyticsController.getMerchantAnalytics);
router.get('/merchants/compare', analyticsController.getMerchantItemComparison);
router.get('/subscriptions', analyticsController.getSubscriptions);

module.exports = router;
