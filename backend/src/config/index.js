/**
 * Purpose: Centralized Application Configuration
 * Responsibilities: Exports environment configuration variables, database URIs, JWT secrets, and defaults.
 * Dependencies: dotenv
 * Author: Antigravity AI
 * Last Modified: 2026-08-03
 */

require('dotenv').config();

module.exports = {
    env: process.env.NODE_ENV || 'development',
    port: process.env.PORT || 5000,
    mongoUri: process.env.MONGO_URI || 'mongodb://localhost:27017/finance_app',
    jwtSecret: process.env.JWT_SECRET || 'supersecretkey_change_in_production_12345',
    jwtExpiration: process.env.JWT_EXPIRATION || '7d',
    refreshTokenSecret: process.env.REFRESH_TOKEN_SECRET || 'refresh_secret_key_98765',
    refreshTokenExpiration: process.env.REFRESH_TOKEN_EXPIRATION || '30d',
    logLevel: process.env.LOG_LEVEL || 'info',
    corsOrigin: process.env.CORS_ORIGIN || '*'
};
