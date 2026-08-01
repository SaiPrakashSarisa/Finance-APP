const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'your_super_secret_jwt_key';
const COOKIE_EXPIRE = parseInt(process.env.COOKIE_EXPIRE) || 7; // days

const sendToken = (user, statusCode, res) => {
    const token = jwt.sign({ id: user._id }, JWT_SECRET, {
        expiresIn: '7d'
    });

    const options = {
        expires: new Date(
            Date.now() + COOKIE_EXPIRE * 24 * 60 * 60 * 1000
        ),
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: process.env.NODE_ENV === "production" ? "none" : "lax"
    };

    res.status(statusCode).cookie('token', token, options).json({
        success: true,
        token,
        user: {
            id: user._id,
            name: user.name,
            email: user.email,
            settings: user.settings
        }
    });
};

const authController = {
    // Register User
    async register(req, res) {
        try {
            const { name, email, password } = req.body;

            if (!name || !email || !password) {
                return res.status(400).json({ success: false, error: 'Please provide name, email and password' });
            }

            // Check if user exists
            const existingUser = await User.findOne({ email });
            if (existingUser) {
                return res.status(400).json({ success: false, error: 'User already exists' });
            }

            // Hash password
            const salt = await bcrypt.genSalt(10);
            const passwordHash = await bcrypt.hash(password, salt);

            // Create user
            const user = await User.create({
                name,
                email,
                passwordHash
            });

            sendToken(user, 201, res);
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    // Login User
    async login(req, res) {
        try {
            const { email, password } = req.body;

            if (!email || !password) {
                return res.status(400).json({ success: false, error: 'Please provide email and password' });
            }

            // Check if user exists and include password
            const user = await User.findOne({ email }).select('+passwordHash');
            if (!user) {
                return res.status(401).json({ success: false, error: 'Invalid credentials' });
            }

            // Verify password
            const isMatch = await bcrypt.compare(password, user.passwordHash);
            if (!isMatch) {
                return res.status(401).json({ success: false, error: 'Invalid credentials' });
            }

            sendToken(user, 200, res);
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    // Get current user profile
    async getMe(req, res) {
        try {
            const user = await User.findById(req.userId);
            res.json({ success: true, user });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    },

    // Logout User
    async logout(req, res) {
        res.cookie('token', 'none', {
            expires: new Date(Date.now() + 10 * 1000),
            httpOnly: true
        });

        res.status(200).json({
            success: true,
            message: 'Logged out successfully'
        });
    }
};

module.exports = authController;
