const mongoose = require('mongoose');
const User = require('./models/User');
const Account = require('./models/Account');
const Category = require('./models/Category');
const Transaction = require('./models/Transaction');
const Credit = require('./models/Credit');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

async function seed() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('Connected to MongoDB');

        const Merchant = require('./models/Merchant');
        const MasterItem = require('./models/MasterItem');

        // Clear existing data
        await Promise.all([
            User.deleteMany({}),
            Account.deleteMany({}),
            Category.deleteMany({}),
            Transaction.deleteMany({}),
            Credit.deleteMany({}),
            Merchant.deleteMany({}),
            MasterItem.deleteMany({})
        ]);
        console.log('Cleared existing data');

        // Create demo user
        const user = await User.create({
            name: 'Demo User',
            email: 'demo@financeapp.com',
            passwordHash: 'demo_hash_placeholder'
        });
        console.log('Created demo user');

        // Create 3 bank accounts
        const [hdfc, sbi, icici] = await Account.create([
            { userId: user._id, name: 'HDFC Salary', type: 'bank', balance: 55000, currency: 'INR' },
            { userId: user._id, name: 'SBI Savings', type: 'bank', balance: 32000, currency: 'INR' },
            { userId: user._id, name: 'ICICI Credit Card', type: 'credit_card', balance: -4500, currency: 'INR' }
        ]);
        console.log('Created 3 accounts');

        // Create categories
        const categories = await Category.create([
            { userId: user._id, name: 'Salary', type: 'income', color: '#10b981', icon: '💰' },
            { userId: user._id, name: 'Freelance', type: 'income', color: '#06b6d4', icon: '💻' },
            { userId: user._id, name: 'Investment Returns', type: 'income', color: '#8b5cf6', icon: '📈' },
            { userId: user._id, name: 'Food & Dining', type: 'expense', color: '#f43f5e', icon: '🍕' },
            { userId: user._id, name: 'Groceries', type: 'expense', color: '#10b981', icon: '🛒' },
            { userId: user._id, name: 'Transport', type: 'expense', color: '#f59e0b', icon: '🚗' },
            { userId: user._id, name: 'Shopping', type: 'expense', color: '#ec4899', icon: '🛍️' },
            { userId: user._id, name: 'Bills & Utilities', type: 'expense', color: '#6366f1', icon: '📱' },
            { userId: user._id, name: 'Entertainment', type: 'expense', color: '#14b8a6', icon: '🎬' },
            { userId: user._id, name: 'Health', type: 'expense', color: '#ef4444', icon: '🏥' },
            { userId: user._id, name: 'Education', type: 'expense', color: '#3b82f6', icon: '📚' }
        ]);
        console.log('Created categories');

        const catMap = {};
        categories.forEach(c => { catMap[c.name] = c._id; });

        // Seed Merchant: D-Mart
        const dmart = await Merchant.create({
            userId: user._id,
            name: 'D-Mart',
            defaultCategoryId: catMap['Groceries'],
            icon: '🛒',
            transactionCount: 2
        });

        // Create sample transactions (including Itemized D-Mart Shopping Trips)
        const now = new Date();
        const m = (monthsAgo, day) => new Date(now.getFullYear(), now.getMonth() - monthsAgo, day);

        await Transaction.create([
            // Month 1 (July) - D-Mart Shopping Trip
            {
                userId: user._id,
                accountId: hdfc._id,
                type: 'expense',
                amount: 1014,
                categoryId: catMap['Groceries'],
                merchantId: dmart._id,
                merchantName: 'D-Mart',
                note: 'Monthly grocery refill',
                date: m(1, 1),
                isItemized: true,
                items: [
                    { name: 'Rice', quantity: 5, unit: 'kg', unitPrice: 64, totalPrice: 320, categoryId: catMap['Groceries'] },
                    { name: 'Milk', quantity: 2, unit: 'L', unitPrice: 32, totalPrice: 64, categoryId: catMap['Groceries'] },
                    { name: 'Soap', quantity: 4, unit: 'pc', unitPrice: 45, totalPrice: 180, categoryId: catMap['Groceries'] },
                    { name: 'Oil', quantity: 2, unit: 'L', unitPrice: 225, totalPrice: 450, categoryId: catMap['Groceries'] }
                ]
            },
            // Current Month (August) - D-Mart Shopping Trip (Price changes!)
            {
                userId: user._id,
                accountId: hdfc._id,
                type: 'expense',
                amount: 1061,
                categoryId: catMap['Groceries'],
                merchantId: dmart._id,
                merchantName: 'D-Mart',
                note: 'August grocery refill',
                date: m(0, 1),
                isItemized: true,
                items: [
                    { name: 'Rice', quantity: 5, unit: 'kg', unitPrice: 70, totalPrice: 350, categoryId: catMap['Groceries'] }, // Rice +₹6/kg (+₹30)
                    { name: 'Milk', quantity: 2, unit: 'L', unitPrice: 33, totalPrice: 66, categoryId: catMap['Groceries'] },  // Milk +₹1/L (+₹2)
                    { name: 'Soap', quantity: 4, unit: 'pc', unitPrice: 41.25, totalPrice: 165, categoryId: catMap['Groceries'] }, // Soap -₹3.75/pc (-₹15)
                    { name: 'Oil', quantity: 2, unit: 'L', unitPrice: 240, totalPrice: 480, categoryId: catMap['Groceries'] }  // Oil +₹15/L (+₹30)
                ]
            },
            // Other transactions
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 75000, categoryId: catMap['Salary'], note: 'Monthly salary', date: m(0, 1) },
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 15000, categoryId: catMap['Freelance'], note: 'Web dev project', date: m(0, 5) },
            { userId: user._id, accountId: icici._id, type: 'expense', amount: 12000, categoryId: catMap['Shopping'], note: 'New shoes and clothes', date: m(0, 7) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 3000, categoryId: catMap['Transport'], note: 'Fuel + metro', date: m(0, 10) }
        ]);
        console.log('Created sample itemized & standard transactions');

        // Create sample credits
        await Credit.create([
            {
                userId: user._id, type: 'given', personName: 'Rahul Sharma',
                amount: 15000, remainingAmount: 15000, linkedAccountId: hdfc._id,
                status: 'active', dueDate: new Date(now.getFullYear(), now.getMonth() + 1, 15),
                notes: 'Emergency loan to friend'
            },
            {
                userId: user._id, type: 'given', personName: 'Priya Patel',
                amount: 5000, remainingAmount: 2500, linkedAccountId: sbi._id,
                status: 'partial', dueDate: new Date(now.getFullYear(), now.getMonth(), 30),
                notes: 'Trip expenses split'
            },
            {
                userId: user._id, type: 'taken', personName: 'Amit Kumar',
                amount: 20000, remainingAmount: 20000, linkedAccountId: hdfc._id,
                status: 'active', dueDate: new Date(now.getFullYear(), now.getMonth() + 2, 1),
                notes: 'Borrowed for home renovation'
            }
        ]);
        console.log('Created 3 sample credits');

        console.log('\n✅ Seed completed successfully!');
        console.log('Demo user: demo@financeapp.com');
        console.log('Accounts: HDFC Salary, SBI Savings, ICICI Credit Card');

        process.exit(0);
    } catch (error) {
        console.error('❌ Seed error:', error.message);
        process.exit(1);
    }
}

seed();
