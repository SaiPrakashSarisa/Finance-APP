require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const accountRoutes = require('./src/routes/accountRoutes');
const transactionRoutes = require('./src/routes/transactionRoutes');
const categoryRoutes = require('./src/routes/categoryRoutes');
const creditRoutes = require('./src/routes/creditRoutes');
const analyticsRoutes = require('./src/routes/analyticsRoutes');
const userRoutes = require('./src/routes/userRoutes');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

// Middleware
app.use(cors());
app.use(express.json());

// Demo user middleware - injects userId into every request
// Replace with proper auth middleware later
const User = require('./src/models/User');
app.use(async (req, res, next) => {
    try {
        let user = await User.findOne({});
        if (!user) {
            user = await User.create({
                name: 'Demo User',
                email: 'demo@financeapp.com',
                passwordHash: 'demo_hash_placeholder'
            });
        }
        req.userId = user._id;
        next();
    } catch (error) {
        next(error);
    }
});

// Routes
app.use('/api/accounts', accountRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/credits', creditRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/user', userRoutes);

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date() });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err.message);
    res.status(500).json({ success: false, error: err.message });
});

// Connect to MongoDB and start server
mongoose.connect(MONGO_URI)
    .then(() => {
        console.log('✅ Connected to MongoDB');
        app.listen(PORT, () => {
            console.log(`🚀 Server running on http://localhost:${PORT}`);
        });
    })
    .catch(err => {
        console.error('❌ MongoDB connection error:', err.message);
        process.exit(1);
    });
