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
const PORT = process.env.PORT || 5001;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app';

const loggerMiddleware = require('./src/middlewares/loggerMiddleware');
const errorHandler = require('./src/middlewares/errorHandler');
const idempotencyMiddleware = require('./src/middleware/idempotency');
const correlationIdMiddleware = require('./src/middleware/correlationId');

// Middleware
const allowedOrigins = [
    "http://localhost:3000",
    "http://localhost:5001",
    "http://10.0.2.2:5001",
    "https://ss-money-manager.vercel.app",
];
app.use(cors({
    origin: function (origin, callback) {
        // Allow requests with no origin (like mobile apps, curl, or Native HTTP clients)
        if (!origin || allowedOrigins.indexOf(origin) !== -1 || origin.startsWith('http://localhost') || origin.startsWith('http://10.0.2.2')) {
            return callback(null, true);
        }
        return callback(null, true);
    },
    credentials: true
}));
app.use(correlationIdMiddleware);
app.use(express.json());
app.use(cookieParser());
app.use(loggerMiddleware);
app.use(idempotencyMiddleware);

// Root Ping & Health Check (Prevents Render 404 logs on cold starts)
app.get('/', (req, res) => res.json({ status: 'ok', service: 'Finance App API', timestamp: new Date() }));
app.head('/', (req, res) => res.status(200).end());
app.get('/api', (req, res) => res.json({ status: 'ok', service: 'Finance App API', timestamp: new Date() }));

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

// Centralized error handler
app.use(errorHandler);

// Connect to MongoDB and start server
mongoose.connect(MONGO_URI, {
    maxPoolSize: 10,
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000
})
    .then(() => {
        console.log('✅ Connected to MongoDB');
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
        });
    })
    .catch(err => {
        console.error('❌ MongoDB connection error:', err.message);
        process.exit(1);
    });
