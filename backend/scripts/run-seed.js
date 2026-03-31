require('dotenv').config();
const mongoose = require('mongoose');
const seedCategories = require('../src/scripts/seedCategories');

const userId = process.argv[2];

if (!userId) {
    console.error('❌ Error: Please provide a User ID as an argument.');
    console.log('Usage: node scripts/run-seed.js <USER_ID>');
    process.exit(1);
}

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

mongoose.connect(MONGO_URI)
    .then(async () => {
        console.log('✅ Connected to MongoDB');
        await seedCategories(userId);
        mongoose.connection.close();
        process.exit(0);
    })
    .catch(err => {
        console.error('❌ MongoDB connection error:', err.message);
        process.exit(1);
    });
