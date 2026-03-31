const mongoose = require('mongoose');

let isReplicaSet = null;

async function checkReplicaSet() {
    if (isReplicaSet !== null) return isReplicaSet;
    try {
        const admin = mongoose.connection.db.admin();
        const status = await admin.serverStatus();
        isReplicaSet = !!status.repl;
        return isReplicaSet;
    } catch (err) {
        console.warn('⚠️ MongoDB Transaction Support: Failed to check replica set status. Defaulting to false.', err.message);
        isReplicaSet = false;
        return false;
    }
}

/**
 * Executes a callback within a MongoDB transaction if supported and enabled.
 * If not supported (e.g. Local Dev without Replica Set), runs the callback without a session.
 * 
 * @param {Function} callback - Async function receiving (session)
 * @returns {Promise<any>} - Result of the callback
 */
async function runInTransaction(callback) {
    const supportsTransactions = (process.env.ENABLE_TRANSACTIONS === 'true') && await checkReplicaSet();
    
    if (!supportsTransactions) {
        // Fallback: Run without session for local standalone development
        return callback(null);
    }

    const session = await mongoose.startSession();
    try {
        let result;
        await session.withTransaction(async () => {
            result = await callback(session);
        });
        return result;
    } catch (error) {
        console.error('❌ Transaction Aborted:', error.message);
        throw error;
    } finally {
        session.endSession();
    }
}

module.exports = {
    runInTransaction,
    checkReplicaSet
};
