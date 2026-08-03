/**
 * Purpose: HTTP Request Logger Middleware
 * Responsibilities: Logs incoming HTTP requests and response times.
 * Dependencies: logger
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 */

const logger = require('../utils/logger');

const loggerMiddleware = (req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        logger.info(`${req.method} ${req.originalUrl} ${res.statusCode} - ${duration}ms`, {
            method: req.method,
            url: req.originalUrl,
            status: res.statusCode,
            duration,
            userId: req.userId || 'anonymous',
            ip: req.ip
        });
    });
    next();
};

module.exports = loggerMiddleware;
