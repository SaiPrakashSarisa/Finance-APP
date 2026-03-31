/**
 * Modular In-Memory Cache Implementation
 * 
 * This cache class provides an interface similar to a Redis client (get, set, del).
 * It uses a Map to store data and handles TTL-based invalidation.
 */
class InMemoryCache {
  constructor() {
    this.store = new Map();
    this.ttls = new Map();
  }

  /**
   * Get value from cache
   * @param {string} key - Cache key
   * @returns {any|null} - Cached value or null if expired/missing
   */
  get(key) {
    const expiresAt = this.ttls.get(key);
    if (expiresAt && Date.now() > expiresAt) {
      this.del(key);
      return null;
    }
    return this.store.get(key) || null;
  }

  /**
   * Set value in cache with TTL
   * @param {string} key - Cache key
   * @param {any} value - Value to store
   * @param {number} ttlSeconds - Time-to-live in seconds (default: 600)
   */
  set(key, value, ttlSeconds = 600) {
    this.store.set(key, value);
    this.ttls.set(key, Date.now() + ttlSeconds * 1000);
  }

  /**
   * Delete value from cache
   * @param {string} key - Cache key
   */
  del(key) {
    this.store.delete(key);
    this.ttls.delete(key);
  }

  /**
   * Clear all cache for a specific user (convenience helper)
   * This is useful when we don't want to track specific analytics keys.
   */
  clearUserCache(userId) {
    // In a more complex scenario, we would prefix keys with `userId:`
    // For now, we simple iterate over keys that start with userId
    for (const key of this.store.keys()) {
      if (key.startsWith(`${userId}:`)) {
        this.del(key);
      }
    }
  }
}

// Singleton instance
const cache = new InMemoryCache();
module.exports = cache;
