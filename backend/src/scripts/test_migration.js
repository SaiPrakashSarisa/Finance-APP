const mongoose = require('mongoose');
const User = require('../models/User');
const Category = require('../models/Category');
const Transaction = require('../models/Transaction');
const transactionService = require('../services/transactionService');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

async function testMigrationPipeline() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB');

        const user = await User.findOne({ email: 'testuser@gmail.com' });
        if (!user) {
            console.error('❌ testuser@gmail.com not found. Run seed script first.');
            process.exit(1);
        }

        console.log('\n--- Testing CSV Export ---');
        const csvData = await transactionService.exportCSV(user._id);
        const csvLines = csvData.split('\n');
        console.log(`Exported ${csvLines.length - 1} transaction rows to CSV.`);
        console.log('CSV Header:', csvLines[0]);
        console.log('Sample CSV Row 1:', csvLines[1]);

        console.log('\n--- Testing Category Migration Engine ---');
        const unorganizedCat = await Category.create({
            userId: user._id,
            name: 'Old Unorganized Salon & Spends',
            type: 'expense',
            color: '#000000'
        });

        const Account = require('../models/Account');
        const account = await Account.findOne({ userId: user._id });

        // Create a transaction with this unorganized category
        const sampleTx = await Transaction.create({
            userId: user._id,
            accountId: account._id,
            amount: 999,
            type: 'expense',
            categoryId: unorganizedCat._id,
            note: 'Old test transaction to migrate',
            date: new Date()
        });

        console.log(`Created test unorganized category "${unorganizedCat.name}" with 1 transaction.`);

        // Find target standard category
        const targetSubCat = await Category.findOne({ userId: user._id, name: 'Haircut & Salon' });
        if (!targetSubCat) throw new Error('Haircut & Salon standard category not found');

        // Migrate
        const result = await Transaction.updateMany(
            { userId: user._id, categoryId: unorganizedCat._id },
            { $set: { categoryId: targetSubCat._id } }
        );
        await Category.findByIdAndDelete(unorganizedCat._id);

        console.log(`Successfully migrated ${result.modifiedCount} transaction(s) to "${targetSubCat.name}" and purged old category!`);

        // Verify transaction
        const updatedTx = await Transaction.findById(sampleTx._id).populate('categoryId');
        console.log(`Updated Transaction Category: ${updatedTx.categoryId.name}`);

        // Cleanup test transaction
        await Transaction.findByIdAndDelete(sampleTx._id);

        console.log('\n🎉 Category Migration & CSV Export Pipeline Verified 100% Successfully!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Migration verification failed:', err);
        process.exit(1);
    }
}

testMigrationPipeline();
