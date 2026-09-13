const mongoose = require('mongoose');
const Category = require('../models/Category');
const Account = require('../models/Account');
const User = require('../models/User');
const categoryController = require('../controllers/categoryController');
const accountService = require('../services/accountService');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

async function runVerification() {
    console.log('🧪 Starting Backend Idempotency & Seeding Verification...');
    await mongoose.connect(MONGO_URI);

    const testEmail = `idempotency_test_${Date.now()}@example.com`;
    const user = await User.create({
        name: 'Idempotency Test User',
        email: testEmail,
        passwordHash: 'hashed_password_123'
    });

    console.log(`✅ Created test user ID: ${user._id}`);

    // 1. Fire 5 concurrent default category seeding operations
    console.log('🔄 Executing 5 parallel category auto-seed calls...');
    await Promise.all([
        categoryController.seedUserDefaultCategories(user._id),
        categoryController.seedUserDefaultCategories(user._id),
        categoryController.seedUserDefaultCategories(user._id),
        categoryController.seedUserDefaultCategories(user._id),
        categoryController.seedUserDefaultCategories(user._id),
    ]);

    const totalCategories = await Category.countDocuments({ userId: user._id });
    console.log(`📊 Total categories created in DB: ${totalCategories}`);

    if (totalCategories === 60) {
        console.log('🎉 SUCCESS: Exact 60 default categories created (NO DUPLICATES under 5 parallel calls)!');
    } else {
        console.error(`❌ FAILED: Expected 60 categories, but found ${totalCategories}`);
        process.exit(1);
    }

    // Clean up test user & categories
    await Category.deleteMany({ userId: user._id });
    await Account.deleteMany({ userId: user._id });
    await User.findByIdAndDelete(user._id);
    console.log('🧹 Test cleanup completed.');

    await mongoose.disconnect();
    console.log('✅ Verification finished successfully!');
}

runVerification().catch(err => {
    console.error('❌ Verification failed:', err);
    process.exit(1);
});
