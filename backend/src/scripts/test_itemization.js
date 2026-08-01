const mongoose = require('mongoose');
const User = require('../models/User');
const analyticsService = require('../services/analyticsService');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

async function testItemizationAnalytics() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB for verification');

        const user = await User.findOne({ email: 'demo@financeapp.com' });
        if (!user) throw new Error('Demo user not found');

        console.log('\n--- Testing Item Price Trend for "Rice" ---');
        const riceTrend = await analyticsService.getItemTrends(user._id, 'Rice');
        console.log('Item:', riceTrend.itemName);
        console.log('First Unit Price:', riceTrend.firstPrice, 'INR');
        console.log('Latest Unit Price:', riceTrend.latestPrice, 'INR');
        console.log('Price Change:', riceTrend.priceChange, 'INR');
        console.log('Inflation %:', riceTrend.inflationPercent, '%');

        console.log('\n--- Testing Personal Inflation Tracker ---');
        const tracker = await analyticsService.getInflationTracker(user._id);
        console.log('Overall Personal Inflation Index:', tracker.overallInflation, '%');
        console.log('Recurring Items Breakdown:');
        console.table(tracker.items.map(i => ({
            Item: i.name,
            Unit: i.unit,
            'July Price': i.firstPrice,
            'August Price': i.lastPrice,
            'Diff (INR)': i.priceDiff,
            'Inflation (%)': i.inflationPercent + '%'
        })));

        process.exit(0);
    } catch (err) {
        console.error('❌ Verification failed:', err);
        process.exit(1);
    }
}

testItemizationAnalytics();
