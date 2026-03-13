const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
    let token;

    if (req.cookies.token) {
        token = req.cookies.token;
    }

    if (!token) {
        return res.status(401).json({ success: false, error: 'Not authorized to access this route' });
    }

    try {
        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_super_secret_jwt_key');

        req.userId = decoded.id;
        next();
    } catch (error) {
        return res.status(401).json({ success: false, error: 'Not authorized to access this route' });
    }
};

module.exports = { protect };
