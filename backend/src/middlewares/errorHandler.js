/**
 * Purpose: Centralized Error Handler Middleware
 * Responsibilities: Catches uncaught application errors and formats standard JSON responses.
 * Dependencies: logger, config
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 * Business Rules:
 *  - Stack traces must never be exposed in production mode.
 */

const logger = require('../utils/logger');
const config = require('../config');

const errorHandler = (err, req, res, next) => {
    const statusCode = err.statusCode || err.status || 500;
    const message = err.message || 'Internal Server Error';

    logger.error('Unhandled Application Error', {
        path: req.originalUrl,
        method: req.method,
        statusCode,
        error: message,
        stack: config.env === 'production' ? undefined : err.stack
    });

    res.status(statusCode).json({
        success: false,
        error: message,
        ...(config.env !== 'production' && { stack: err.stack })
    });
};

module.exports = errorHandler;
