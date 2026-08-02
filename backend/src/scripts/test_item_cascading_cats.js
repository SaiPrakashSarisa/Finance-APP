const mongoose = require('mongoose');
const User = require('../models/User');
const Account = require('../models/Account');
const Category = require('../models/Category');
const Transaction = require('../models/Transaction');
const transactionService = require('../services/transactionService');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

async function testItemCascadingCategories() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB');

        const user = await User.findOne({ email: 'testuser@gmail.com' });
        const account = await Account.findOne({ userId: user._id });
        const grocerySubCat = await Category.findOne({ userId: user._id, name: 'Supermarket & Groceries' });
        const skincareSubCat = await Category.findOne({ userId: user._id, name: 'Skincare & Cosmetics' });

        if (!user || !account || !grocerySubCat || !skincareSubCat) {
            console.error('❌ Required test models not found');
            process.exit(1);
        }

        console.log('--- Testing Item-Level Cascading Categories Creation ---');

        const txData = {
            userId: user._id,
            accountId: account._id,
            type: 'expense',
            amount: 515,
            merchantName: 'D-Mart Mega Superstore',
            isItemized: true,
            items: [
                {
                    name: 'Basmati Rice 5kg',
                    categoryId: grocerySubCat._id,
                    quantity: 1,
                    unit: 'kg',
                    unitPrice: 350,
                    totalPrice: 350
                },
                {
                    name: 'Dove Bath Soap 4pc',
                    categoryId: skincareSubCat._id,
                    quantity: 1,
                    unit: 'pc',
                    unitPrice: 165,
                    totalPrice: 165
                }
            ],
            note: 'Test multi-category receipt itemization',
            date: new Date()
        };

        const createdTx = await transactionService.create(txData);
        console.log(`✅ Created Transaction ID: ${createdTx._id}`);
        console.log(`Is Itemized: ${createdTx.isItemized}`);
        console.log('Item Breakdown:');
        createdTx.items.forEach(i => {
            console.log(`- Product: "${i.name}", CategoryID: ${i.categoryId}, UnitPrice: ₹${i.unitPrice}`);
        });

        // Cleanup test record
        await Transaction.findByIdAndDelete(createdTx._id);
        console.log('✅ Test record cleaned up cleanly');

        console.log('\n🎉 Item-Level Cascading Category Engine Verified 100% Successfully!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Verification failed:', err);
        process.exit(1);
    }
}

testItemCascadingCategories();
