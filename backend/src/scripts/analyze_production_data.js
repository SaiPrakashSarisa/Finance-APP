const mongoose = require('mongoose');
const dns = require('dns');

// Force Google Public DNS for SRV resolution
try {
    dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (e) {}

const PROD_URI = 'mongodb+srv://saiprakashsarisa:saiMongoDB99@emp001.7fm0lll.mongodb.net/finance_app?retryWrites=true&w=majority&appName=Emp001';

async function inspectProductionData() {
    try {
        console.log('Connecting to Production MongoDB Atlas (READ-ONLY)...');
        await mongoose.connect(PROD_URI, { family: 4, serverSelectionTimeoutMS: 15000 });
        console.log('✅ Connected to Production MongoDB Atlas!');

        const User = mongoose.model('User', new mongoose.Schema({}, { strict: false }));
        const Category = mongoose.model('Category', new mongoose.Schema({}, { strict: false }));
        const Transaction = mongoose.model('Transaction', new mongoose.Schema({}, { strict: false }));
        const Account = mongoose.model('Account', new mongoose.Schema({}, { strict: false }));

        const user = await User.findOne({ email: 'saiprakashsarisa@gmail.com' });
        if (!user) {
            console.error('❌ User saiprakashsarisa@gmail.com not found in production DB');
            process.exit(1);
        }

        console.log(`Found Production User: ${user.name} (${user.email}), ID: ${user._id}`);

        // Fetch all categories
        const categories = await Category.find({ userId: user._id });
        console.log(`\n--- Production Current Categories (${categories.length} total) ---`);
        const catMap = {};
        categories.forEach(c => {
            catMap[c._id.toString()] = c;
            console.log(`- [${c.type.toUpperCase()}] "${c.name}" (Color: ${c.color}, Icon: ${c.icon || 'none'}, ParentId: ${c.parentCategoryId || 'none'})`);
        });

        // Fetch all transactions
        const transactions = await Transaction.find({ userId: user._id }).sort({ date: -1 });
        console.log(`\n--- Total Production Transactions: ${transactions.length} ---`);

        // Group transactions by category name
        const grouped = {};
        const unassigned = [];
        
        transactions.forEach(t => {
            const catIdStr = t.categoryId ? t.categoryId.toString() : null;
            const cat = catIdStr ? catMap[catIdStr] : null;
            const catName = cat ? cat.name : (t.category || 'Uncategorized');

            if (!grouped[catName]) {
                grouped[catName] = {
                    count: 0,
                    totalAmount: 0,
                    type: t.type,
                    notes: new Set(),
                    merchants: new Set()
                };
            }

            grouped[catName].count++;
            grouped[catName].totalAmount += (t.amount || 0);
            if (t.note) grouped[catName].notes.add(t.note);
            if (t.merchantName) grouped[catName].merchants.add(t.merchantName);
        });

        console.log('\n--- Production Category Spending Summary ---');
        const summary = Object.entries(grouped).map(([name, data]) => ({
            categoryName: name,
            type: data.type,
            count: data.count,
            totalAmount: data.totalAmount,
            sampleNotes: Array.from(data.notes).slice(0, 5),
            sampleMerchants: Array.from(data.merchants).slice(0, 5)
        }));

        summary.sort((a, b) => b.totalAmount - a.totalAmount);

        console.dir(summary, { depth: null });

        process.exit(0);
    } catch (err) {
        console.error('❌ Error inspecting production data:', err);
        process.exit(1);
    }
}

inspectProductionData();
