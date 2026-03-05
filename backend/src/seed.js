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

        // Clear existing data
        await Promise.all([
            User.deleteMany({}),
            Account.deleteMany({}),
            Category.deleteMany({}),
            Transaction.deleteMany({}),
            Credit.deleteMany({})
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
            { userId: user._id, name: 'Transport', type: 'expense', color: '#f59e0b', icon: '🚗' },
            { userId: user._id, name: 'Shopping', type: 'expense', color: '#ec4899', icon: '🛍️' },
            { userId: user._id, name: 'Bills & Utilities', type: 'expense', color: '#6366f1', icon: '📱' },
            { userId: user._id, name: 'Entertainment', type: 'expense', color: '#14b8a6', icon: '🎬' },
            { userId: user._id, name: 'Health', type: 'expense', color: '#ef4444', icon: '🏥' },
            { userId: user._id, name: 'Education', type: 'expense', color: '#3b82f6', icon: '📚' }
        ]);
        console.log('Created 10 categories');

        const catMap = {};
        categories.forEach(c => { catMap[c.name] = c._id; });

        // Create sample transactions (last 3 months)
        const now = new Date();
        const m = (monthsAgo, day) => {
            const d = new Date(now.getFullYear(), now.getMonth() - monthsAgo, day);
            return d;
        };

        await Transaction.create([
            // Current month
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 75000, categoryId: catMap['Salary'], note: 'Monthly salary', date: m(0, 1) },
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 15000, categoryId: catMap['Freelance'], note: 'Web dev project', date: m(0, 5) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 4500, categoryId: catMap['Food & Dining'], note: 'Groceries + restaurants', date: m(0, 3) },
            { userId: user._id, accountId: icici._id, type: 'expense', amount: 12000, categoryId: catMap['Shopping'], note: 'New shoes and clothes', date: m(0, 7) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 3000, categoryId: catMap['Transport'], note: 'Fuel + metro', date: m(0, 10) },
            { userId: user._id, accountId: sbi._id, type: 'expense', amount: 5500, categoryId: catMap['Bills & Utilities'], note: 'Electricity + Internet', date: m(0, 8) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 2000, categoryId: catMap['Entertainment'], note: 'Movie + Netflix', date: m(0, 12) },
            { userId: user._id, accountId: hdfc._id, type: 'transfer', amount: 10000, note: 'Savings transfer', date: m(0, 2), toAccountId: sbi._id },

            // Last month
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 75000, categoryId: catMap['Salary'], note: 'Monthly salary', date: m(1, 1) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 6000, categoryId: catMap['Food & Dining'], note: 'Groceries', date: m(1, 5) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 8000, categoryId: catMap['Shopping'], note: 'Electronics', date: m(1, 10) },
            { userId: user._id, accountId: sbi._id, type: 'expense', amount: 4500, categoryId: catMap['Bills & Utilities'], note: 'Bills', date: m(1, 8) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 2500, categoryId: catMap['Transport'], note: 'Fuel', date: m(1, 15) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 3500, categoryId: catMap['Health'], note: 'Doctor + medicines', date: m(1, 20) },
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 5000, categoryId: catMap['Investment Returns'], note: 'Dividend', date: m(1, 25) },

            // 2 months ago
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 75000, categoryId: catMap['Salary'], note: 'Monthly salary', date: m(2, 1) },
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 20000, categoryId: catMap['Freelance'], note: 'App development', date: m(2, 12) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 5000, categoryId: catMap['Food & Dining'], note: 'Groceries', date: m(2, 4) },
            { userId: user._id, accountId: icici._id, type: 'expense', amount: 15000, categoryId: catMap['Shopping'], note: 'Laptop accessories', date: m(2, 8) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 7000, categoryId: catMap['Education'], note: 'Online course', date: m(2, 15) },
        ]);
        console.log('Created 20 sample transactions');

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
