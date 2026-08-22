#!/usr/bin/env node

/**
 * Hit Counter Application - Main Entry Point
 * Supports PostgreSQL and MySQL databases
 */

const { config, validateConfig } = require('./config');
const logger = require('./logger');
const db = require('./db');
const createServer = require('./server');

/**
 * Start the application
 */
async function start() {
  try {
    logger.info('Starting Hit Counter Application');
    logger.info(`Environment: ${config.app.env}`);
    logger.info(`Database: ${config.database.type} (${config.database.endpoint}:${config.database.port})`);

    // Validate configuration
    validateConfig();
    logger.info('Configuration validated');

    // Initialize database
    await db.initializePool();
    await db.initializeTables();
    await db.initializeCounter();
    logger.info('Database initialized');

    // Create and start server
    const app = createServer();
    const server = app.listen(config.app.port, () => {
      logger.info(`Server listening on port ${config.app.port}`);
      logger.info(`Application ready at http://localhost:${config.app.port}`);
      logger.info(`Health check available at http://localhost:${config.app.port}/health`);
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      logger.info('SIGTERM signal received: closing HTTP server');
      server.close(async () => {
        logger.info('HTTP server closed');
        await db.closePool();
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      logger.info('SIGINT signal received: closing HTTP server');
      server.close(async () => {
        logger.info('HTTP server closed');
        await db.closePool();
        process.exit(0);
      });
    });

  } catch (error) {
    logger.error(`Failed to start application: ${error.message}`);
    logger.error(error.stack);
    process.exit(1);
  }
}

// Start the application
start();
