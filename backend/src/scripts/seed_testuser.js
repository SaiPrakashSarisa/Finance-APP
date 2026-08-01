const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Account = require('../models/Account');
const Category = require('../models/Category');
const Transaction = require('../models/Transaction');
const Credit = require('../models/Credit');
const Merchant = require('../models/Merchant');
const MasterItem = require('../models/MasterItem');
const Budget = require('../models/Budget');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

async function seedTestUser() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB');

        const email = 'testuser@gmail.com';
        
        // Find or create testuser
        let user = await User.findOne({ email });
        if (user) {
            console.log('Clearing existing data for testuser@gmail.com...');
            await Promise.all([
                Account.deleteMany({ userId: user._id }),
                Category.deleteMany({ userId: user._id }),
                Transaction.deleteMany({ userId: user._id }),
                Credit.deleteMany({ userId: user._id }),
                Merchant.deleteMany({ userId: user._id }),
                MasterItem.deleteMany({ userId: user._id }),
                Budget.deleteMany({ userId: user._id })
            ]);
            const salt = await bcrypt.genSalt(10);
            user.passwordHash = await bcrypt.hash('test123', salt);
            await user.save();
        } else {
            console.log('Creating new user testuser@gmail.com...');
            const salt = await bcrypt.genSalt(10);
            const passwordHash = await bcrypt.hash('test123', salt);
            user = await User.create({
                name: 'Test User',
                email,
                passwordHash
            });
        }

        console.log('Creating accounts...');
        const [hdfc, sbi, icici, cashWallet] = await Account.create([
            { userId: user._id, name: 'HDFC Salary Account', type: 'bank', balance: 85000, currency: 'INR' },
            { userId: user._id, name: 'SBI Savings Account', type: 'bank', balance: 42000, currency: 'INR' },
            { userId: user._id, name: 'ICICI Amazon Credit Card', type: 'credit_card', balance: -6200, currency: 'INR' },
            { userId: user._id, name: 'Cash Wallet', type: 'cash', balance: 3500, currency: 'INR' }
        ]);

        console.log('Creating real-world parent & sub-categories...');
        // Income Categories
        const catSalary = await Category.create({ userId: user._id, name: 'Salary & Earnings', type: 'income', color: '#10b981', icon: '💰' });
        const subPrimarySalary = await Category.create({ userId: user._id, name: 'Primary Salary', type: 'income', color: '#10b981', icon: '💵', parentCategoryId: catSalary._id });
        const subFreelance = await Category.create({ userId: user._id, name: 'Freelance & Consulting', type: 'income', color: '#06b6d4', icon: '💻', parentCategoryId: catSalary._id });
        
        const catInvestments = await Category.create({ userId: user._id, name: 'Investments', type: 'income', color: '#8b5cf6', icon: '📈' });
        const subDividends = await Category.create({ userId: user._id, name: 'Stock Dividends', type: 'income', color: '#8b5cf6', icon: '📊', parentCategoryId: catInvestments._id });

        // Expense Categories
        const catFood = await Category.create({ userId: user._id, name: 'Food & Groceries', type: 'expense', color: '#f43f5e', icon: '🛒' });
        const subGroceries = await Category.create({ userId: user._id, name: 'Supermarket & Groceries', type: 'expense', color: '#10b981', icon: '🥬', parentCategoryId: catFood._id });
        const subDining = await Category.create({ userId: user._id, name: 'Restaurants & Dining Out', type: 'expense', color: '#f43f5e', icon: '🍕', parentCategoryId: catFood._id });
        const subCoffee = await Category.create({ userId: user._id, name: 'Coffee & Snacks', type: 'expense', color: '#d97706', icon: '☕', parentCategoryId: catFood._id });

        const catHousing = await Category.create({ userId: user._id, name: 'Housing & Utilities', type: 'expense', color: '#6366f1', icon: '🏠' });
        const subRent = await Category.create({ userId: user._id, name: 'House Rent', type: 'expense', color: '#6366f1', icon: '🔑', parentCategoryId: catHousing._id });
        const subElectricity = await Category.create({ userId: user._id, name: 'Electricity & Gas', type: 'expense', color: '#eab308', icon: '⚡', parentCategoryId: catHousing._id });
        const subWifi = await Category.create({ userId: user._id, name: 'WiFi & Broadband', type: 'expense', color: '#3b82f6', icon: '📶', parentCategoryId: catHousing._id });

        const catTransport = await Category.create({ userId: user._id, name: 'Transportation', type: 'expense', color: '#f59e0b', icon: '🚗' });
        const subFuel = await Category.create({ userId: user._id, name: 'Petrol & Fuel', type: 'expense', color: '#f59e0b', icon: '⛽', parentCategoryId: catTransport._id });
        const subCab = await Category.create({ userId: user._id, name: 'Uber & Cab Booking', type: 'expense', color: '#14b8a6', icon: '🚕', parentCategoryId: catTransport._id });

        const catShopping = await Category.create({ userId: user._id, name: 'Shopping & Apparel', type: 'expense', color: '#ec4899', icon: '🛍️' });
        const subApparel = await Category.create({ userId: user._id, name: 'Clothing & Footwear', type: 'expense', color: '#ec4899', icon: '👕', parentCategoryId: catShopping._id });

        // 1. Personal Care & Grooming (Haircut, Skincare, Cosmetics)
        const catPersonalCare = await Category.create({ userId: user._id, name: 'Personal Care & Grooming', type: 'expense', color: '#a855f7', icon: '✂️' });
        const subHaircut = await Category.create({ userId: user._id, name: 'Haircut & Salon', type: 'expense', color: '#a855f7', icon: '✂️', parentCategoryId: catPersonalCare._id });
        const subSkincare = await Category.create({ userId: user._id, name: 'Skincare & Cosmetics', type: 'expense', color: '#f472b6', icon: '🧴', parentCategoryId: catPersonalCare._id });

        // 2. Giving & Charity (Helping poor people, donations, tips)
        const catGiving = await Category.create({ userId: user._id, name: 'Giving & Charity', type: 'expense', color: '#06b6d4', icon: '🤝' });
        const subCharity = await Category.create({ userId: user._id, name: 'Helping Needy & Street Charity', type: 'expense', color: '#06b6d4', icon: '🤝', parentCategoryId: catGiving._id });
        const subTipping = await Category.create({ userId: user._id, name: 'Donations & Tipping', type: 'expense', color: '#38bdf8', icon: '🎁', parentCategoryId: catGiving._id });

        // 3. Unaccounted & Miscellaneous (Expenses forgotten or lost track of)
        const catMisc = await Category.create({ userId: user._id, name: 'Miscellaneous & Adjustments', type: 'expense', color: '#94a3b8', icon: '❓' });
        const subUnaccounted = await Category.create({ userId: user._id, name: 'Unaccounted / Forgot Spent', type: 'expense', color: '#64748b', icon: '❓', parentCategoryId: catMisc._id });
        const subCashAdjust = await Category.create({ userId: user._id, name: 'Cash Balance Adjustment', type: 'expense', color: '#475569', icon: '⚖️', parentCategoryId: catMisc._id });

        console.log('Creating Merchants...');
        const dmart = await Merchant.create({ userId: user._id, name: 'D-Mart', defaultCategoryId: subGroceries._id, icon: '🛒', transactionCount: 2 });
        const reliance = await Merchant.create({ userId: user._id, name: 'Reliance Fresh', defaultCategoryId: subGroceries._id, icon: '🥦', transactionCount: 1 });
        const hpPump = await Merchant.create({ userId: user._id, name: 'HP Fuel Station', defaultCategoryId: subFuel._id, icon: '⛽', transactionCount: 2 });
        const nykaa = await Merchant.create({ userId: user._id, name: 'Nykaa Cosmetics', defaultCategoryId: subSkincare._id, icon: '💄', transactionCount: 1 });
        const salon = await Merchant.create({ userId: user._id, name: 'Naturals Salon', defaultCategoryId: subHaircut._id, icon: '✂️', transactionCount: 1 });

        const now = new Date();
        const m = (monthsAgo, day) => new Date(now.getFullYear(), now.getMonth() - monthsAgo, day);

        console.log('Creating Itemized Transactions & Inflation Data...');
        await Transaction.create([
            // July D-Mart Trip (Baseline Prices)
            {
                userId: user._id,
                accountId: hdfc._id,
                type: 'expense',
                amount: 1240,
                categoryId: subGroceries._id,
                merchantId: dmart._id,
                merchantName: 'D-Mart',
                note: 'July monthly kitchen & grocery refill',
                date: m(1, 2),
                isItemized: true,
                items: [
                    { name: 'Basmati Rice', quantity: 5, unit: 'kg', unitPrice: 64, totalPrice: 320, categoryId: subGroceries._id },
                    { name: 'Sunflower Cooking Oil', quantity: 2, unit: 'L', unitPrice: 225, totalPrice: 450, categoryId: subGroceries._id },
                    { name: 'Amul Taaza Milk', quantity: 4, unit: 'L', unitPrice: 32, totalPrice: 128, categoryId: subGroceries._id },
                    { name: 'Dove Bath Soap', quantity: 4, unit: 'pc', unitPrice: 45, totalPrice: 180, categoryId: subGroceries._id },
                    { name: 'Aashirvaad Whole Wheat Atta', quantity: 5, unit: 'kg', unitPrice: 32, totalPrice: 160, categoryId: subGroceries._id }
                ]
            },
            // August D-Mart Trip (Inflation Comparison - Rice +9.38%, Oil +6.67%, Milk +3.13%, Atta +9.38%, Soap -8.33%)
            {
                userId: user._id,
                accountId: hdfc._id,
                type: 'expense',
                amount: 1301,
                categoryId: subGroceries._id,
                merchantId: dmart._id,
                merchantName: 'D-Mart',
                note: 'August monthly grocery refill',
                date: m(0, 1),
                isItemized: true,
                items: [
                    { name: 'Basmati Rice', quantity: 5, unit: 'kg', unitPrice: 70, totalPrice: 350, categoryId: subGroceries._id },       // Rice +6/kg (+30 total)
                    { name: 'Sunflower Cooking Oil', quantity: 2, unit: 'L', unitPrice: 240, totalPrice: 480, categoryId: subGroceries._id }, // Oil +15/L (+30 total)
                    { name: 'Amul Taaza Milk', quantity: 4, unit: 'L', unitPrice: 33, totalPrice: 132, categoryId: subGroceries._id },       // Milk +1/L (+4 total)
                    { name: 'Dove Bath Soap', quantity: 4, unit: 'pc', unitPrice: 41.25, totalPrice: 165, categoryId: subGroceries._id },    // Soap -3.75/pc (-15 total)
                    { name: 'Aashirvaad Whole Wheat Atta', quantity: 5, unit: 'kg', unitPrice: 35, totalPrice: 174, categoryId: subGroceries._id } // Atta +3/kg (+14 total)
                ]
            },
            // Reliance Fresh Trip (Vegetables & Fruits)
            {
                userId: user._id,
                accountId: cashWallet._id,
                type: 'expense',
                amount: 450,
                categoryId: subGroceries._id,
                merchantId: reliance._id,
                merchantName: 'Reliance Fresh',
                note: 'Fresh fruits and organic vegetables',
                date: m(0, 3),
                isItemized: true,
                items: [
                    { name: 'Organic Apples', quantity: 1.5, unit: 'kg', unitPrice: 160, totalPrice: 240, categoryId: subGroceries._id },
                    { name: 'Fresh Tomatoes', quantity: 2, unit: 'kg', unitPrice: 35, totalPrice: 70, categoryId: subGroceries._id },
                    { name: 'Onions', quantity: 3, unit: 'kg', unitPrice: 46.67, totalPrice: 140, categoryId: subGroceries._id }
                ]
            },
            // Income & Regular Expenses
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 95000, categoryId: subPrimarySalary._id, note: 'Monthly Salary Credit', date: m(0, 1) },
            { userId: user._id, accountId: hdfc._id, type: 'income', amount: 25000, categoryId: subFreelance._id, note: 'Web App Consulting Project', date: m(0, 5) },
            { userId: user._id, accountId: sbi._id, type: 'income', amount: 4500, categoryId: subDividends._id, note: 'Quarterly Mutual Fund Dividend', date: m(0, 10) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 22000, categoryId: subRent._id, note: 'Monthly Apartment Rent', date: m(0, 1) },
            { userId: user._id, accountId: sbi._id, type: 'expense', amount: 3400, categoryId: subElectricity._id, note: 'Electricity Bill', date: m(0, 8) },
            { userId: user._id, accountId: hdfc._id, type: 'expense', amount: 1199, categoryId: subWifi._id, note: 'JioFiber 300Mbps Plan', date: m(0, 10) },
            { userId: user._id, accountId: icici._id, type: 'expense', amount: 3500, categoryId: subFuel._id, merchantId: hpPump._id, merchantName: 'HP Fuel Station', note: 'Car Tank Full Petrol', date: m(0, 7) },
            { userId: user._id, accountId: icici._id, type: 'expense', amount: 6500, categoryId: subApparel._id, note: 'Nike Running Shoes', date: m(0, 12) },
            
            // New Requested Real-World Expenses
            { userId: user._id, accountId: cashWallet._id, type: 'expense', amount: 350, categoryId: subHaircut._id, merchantId: salon._id, merchantName: 'Naturals Salon', note: 'Haircut & Styling', date: m(0, 4) },
            { userId: user._id, accountId: icici._id, type: 'expense', amount: 1250, categoryId: subSkincare._id, merchantId: nykaa._id, merchantName: 'Nykaa Cosmetics', note: 'Sunscreen & Face Wash Skincare', date: m(0, 6) },
            { userId: user._id, accountId: cashWallet._id, type: 'expense', amount: 500, categoryId: subCharity._id, note: 'Food & cash assistance to street family', date: m(0, 9) },
            { userId: user._id, accountId: cashWallet._id, type: 'expense', amount: 250, categoryId: subUnaccounted._id, note: 'Small cash spends lost track of', date: m(0, 11) }
        ]);

        console.log('Creating Budgets...');
        await Budget.create([
            { userId: user._id, categoryId: catFood._id, amount: 15000, month: now.getMonth() + 1, year: now.getFullYear() },
            { userId: user._id, categoryId: catHousing._id, amount: 30000, month: now.getMonth() + 1, year: now.getFullYear() },
            { userId: user._id, categoryId: catTransport._id, amount: 8000, month: now.getMonth() + 1, year: now.getFullYear() }
        ]);

        console.log('Creating Credits...');
        await Credit.create([
            {
                userId: user._id, type: 'given', personName: 'Suresh Kumar',
                amount: 10000, remainingAmount: 10000, linkedAccountId: hdfc._id,
                status: 'active', dueDate: m(-1, 15), notes: 'Personal loan to colleague'
            },
            {
                userId: user._id, type: 'taken', personName: 'Ramesh Patel',
                amount: 15000, remainingAmount: 5000, linkedAccountId: sbi._id,
                status: 'partial', dueDate: m(-1, 30), notes: 'Home appliance purchase assistance'
            }
        ]);

        console.log('\n🎉 Successfully seeded testuser@gmail.com!');
        console.log('Email: testuser@gmail.com');
        console.log('Password: test123');
        process.exit(0);
    } catch (err) {
        console.error('❌ Seeding error:', err);
        process.exit(1);
    }
}

seedTestUser();
