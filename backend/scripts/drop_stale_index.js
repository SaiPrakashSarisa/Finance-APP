require('dotenv').config();
const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

async function dropIndex() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB');

        const collection = mongoose.connection.collection('budgets');
        const staleIndexes = ['userId_1_categoryId_1_yearMonth_1', 'userId_1_categoryId_1_validFrom_1'];

        for (const indexName of staleIndexes) {
            console.log(`🔍 Checking for index: ${indexName}...`);
            const indexes = await collection.indexes();
            const indexExists = indexes.some(idx => idx.name === indexName);

            if (indexExists) {
                await collection.dropIndex(indexName);
                console.log(`✅ Successfully dropped index: ${indexName}`);
            } else {
                console.log(`ℹ️ Index ${indexName} does not exist.`);
            }
        }

        // List remaining indexes for confirmation
        const remainingIndexes = await collection.indexes();
        console.log('📊 Current indexes on budgets collection:');
        remainingIndexes.forEach(idx => console.log(` - ${idx.name}`));

        await mongoose.disconnect();
        console.log('👋 Disconnected from MongoDB');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error dropping index:', error.message);
        process.exit(1);
    }
}

dropIndex();
