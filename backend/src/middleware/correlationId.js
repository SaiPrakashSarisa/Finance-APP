const { randomUUID } = require('crypto');

/**
 * Middleware: Request Correlation ID Generator
 * Description: Attaches a unique X-Request-ID UUID to every incoming HTTP request for distributed tracing & diagnostics.
 */
function correlationIdMiddleware(req, res, next) {
    const requestId = req.headers['x-request-id'] || randomUUID();
    req.requestId = requestId;
    res.setHeader('X-Request-ID', requestId);
    next();
}

module.exports = correlationIdMiddleware;
