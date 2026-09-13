const IdempotencyKey = require('../models/IdempotencyKey');

/**
 * Middleware: Express Idempotency Interceptor
 * Description: Ensures POST/PUT/PATCH/DELETE mutation requests containing an X-Idempotency-Key header execute at most once.
 */
async function idempotencyMiddleware(req, res, next) {
    const key = req.headers['x-idempotency-key'] || req.headers['idempotency-key'];

    // Only apply idempotency to mutation operations (POST, PUT, PATCH, DELETE) when a key is provided
    if (!key || ['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
        return next();
    }

    try {
        const existingKey = await IdempotencyKey.findOne({ key });

        if (existingKey) {
            if (existingKey.status === 'completed') {
                return res.status(existingKey.responseStatus).json(existingKey.responseBody);
            }
            if (existingKey.status === 'processing') {
                return res.status(409).json({
                    success: false,
                    error: 'A request with this Idempotency-Key is currently being processed. Please wait.'
                });
            }
        }

        // Reserve idempotency key in processing state
        let record;
        try {
            record = await IdempotencyKey.create({
                key,
                userId: req.userId || null,
                path: req.originalUrl || req.path,
                method: req.method,
                status: 'processing'
            });
        } catch (err) {
            if (err.code === 11000) {
                // Duplicate key error - another request just reserved this key concurrently
                return res.status(409).json({
                    success: false,
                    error: 'Concurrent request detected for this Idempotency-Key.'
                });
            }
            throw err;
        }

        // Intercept res.json to capture response status and body
        const originalJson = res.json.bind(res);
        res.json = (body) => {
            const statusCode = res.statusCode || 200;
            const finalStatus = statusCode < 400 ? 'completed' : 'failed';

            // Async update record in background without blocking response transmission
            IdempotencyKey.updateOne(
                { _id: record._id },
                {
                    $set: {
                        status: finalStatus,
                        responseStatus: statusCode,
                        responseBody: body,
                        userId: req.userId || record.userId
                    }
                }
            ).catch(err => {
                console.error('Failed to save idempotency response payload:', err.message);
            });

            return originalJson(body);
        };

        next();
    } catch (error) {
        console.error('Idempotency middleware error:', error);
        next(error);
    }
}

module.exports = idempotencyMiddleware;
