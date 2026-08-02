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
const budgetRoutes = require('./src/routes/budgetRoutes');
const masterItemRoutes = require('./src/routes/masterItemRoutes');

const cookieParser = require('cookie-parser');
const authRoutes = require('./src/routes/authRoutes');
const { protect } = require('./src/middleware/authMiddleware');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

// Middleware
const allowedOrigins = [
    "http://localhost:3000",
    "https://ss-money-manager.vercel.app",
];
app.use(cors({
    origin: allowedOrigins,
    credentials: true
}));
app.use(express.json());
app.use(cookieParser());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/accounts', protect, accountRoutes);
app.use('/api/transactions', protect, transactionRoutes);
app.use('/api/categories', protect, categoryRoutes);
app.use('/api/credits', protect, creditRoutes);
app.use('/api/analytics', protect, analyticsRoutes);
app.use('/api/user', protect, userRoutes);
app.use('/api/budgets', protect, budgetRoutes);
app.use('/api/master-items', protect, masterItemRoutes);

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
