/**
 * Express server setup and middleware configuration
 */

const express = require('express');
const { config } = require('./config');
const logger = require('./logger');

function createServer() {
  const app = express();

  // Middleware
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // Request logging middleware
  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      logger.info(`${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
    });
    next();
  });

  // Health endpoint (before routes to be fast)
  app.get('/health', (req, res) => {
    res.status(200).json({
      status: 'ready',
      uptime: process.uptime(),
      database: config.database.type
    });
  });

  // Routes
  app.use(require('./routes'));

  // 404 handler
  app.use((req, res) => {
    res.status(404).json({
      error: 'Not Found',
      path: req.path
    });
  });

  // Error handler
  app.use((err, req, res, next) => {
    logger.error(`Unhandled error: ${err.message}`);
    res.status(500).json({
      error: 'Internal Server Error',
      message: config.app.env === 'development' ? err.message : undefined
    });
  });

  return app;
}

module.exports = createServer;
