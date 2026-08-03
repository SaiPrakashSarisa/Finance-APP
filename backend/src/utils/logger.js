/**
 * Purpose: Structured Production Logger
 * Responsibilities: Formats and logs events, errors, authentication, transactions, and audit entries.
 * Dependencies: config, constants
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 */

const config = require('../config');

const sanitizeData = (data) => {
    if (!data || typeof data !== 'object') return data;
    const sanitized = { ...data };
    const sensitiveKeys = ['password', 'passwordHash', 'token', 'refreshToken', 'authorization', 'secret'];
    
    for (const key of Object.keys(sanitized)) {
        if (sensitiveKeys.includes(key.toLowerCase())) {
            sanitized[key] = '[REDACTED]';
        } else if (typeof sanitized[key] === 'object') {
            sanitized[key] = sanitizeData(sanitized[key]);
        }
    }
    return sanitized;
};

const formatMessage = (level, message, meta = {}) => {
    const timestamp = new Date().toISOString();
    const cleanMeta = sanitizeData(meta);
    return JSON.stringify({
        timestamp,
        level: level.toUpperCase(),
        message,
        ...cleanMeta
    });
};

const logger = {
    info(message, meta) {
        console.log(formatMessage('info', message, meta));
    },
    warn(message, meta) {
        console.warn(formatMessage('warn', message, meta));
    },
    error(message, meta) {
        console.error(formatMessage('error', message, meta));
    },
    audit(message, meta) {
        console.log(formatMessage('audit', message, meta));
    },
    transaction(message, meta) {
        console.log(formatMessage('transaction', message, meta));
    }
};

module.exports = logger;
