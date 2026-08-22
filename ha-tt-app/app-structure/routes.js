/**
 * Route handlers for the application
 */

const express = require('express');
const db = require('./db');
const { config } = require('./config');
const logger = require('./logger');

const router = express.Router();

/**
 * Health check endpoint
 * Returns: { status: 'healthy' | 'unhealthy', db: 'postgres' | 'mysql' }
 */
router.get('/health', async (req, res) => {
  try {
    const isHealthy = await db.healthCheck();

    if (isHealthy) {
      res.status(200).json({
        status: 'healthy',
        db: config.database.type,
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(503).json({
        status: 'unhealthy',
        db: config.database.type,
        message: 'Database connection failed'
      });
    }
  } catch (error) {
    logger.error(`Health check error: ${error.message}`);
    res.status(503).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

/**
 * Main page - displays hit counter
 * Increments counter on each request (demonstrates write operation)
 */
router.get('/', async (req, res) => {
  try {
    await db.incrementCounter();
    const hitData = await db.getHitData();

    const hitCount = hitData.hit_count;
    const lastHit = new Date(hitData.last_hit).toLocaleString();

    const dbTypeLabel = config.database.type === 'postgres' ? 'PostgreSQL' : 'MySQL';

    res.status(200).send(`
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Hit Counter App</title>
          <style>
            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }

            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              min-height: 100vh;
              display: flex;
              justify-content: center;
              align-items: center;
              padding: 20px;
            }

            .container {
              background: white;
              padding: 40px;
              border-radius: 12px;
              box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
              max-width: 400px;
              width: 100%;
              text-align: center;
            }

            .header {
              margin-bottom: 30px;
            }

            .label {
              font-size: 18px;
              color: #666;
              margin-bottom: 15px;
              font-weight: 500;
            }

            .count {
              font-size: 72px;
              font-weight: bold;
              color: #667eea;
              margin: 20px 0;
              line-height: 1;
            }

            .timestamp {
              font-size: 13px;
              color: #999;
              margin-top: 25px;
              font-family: 'Monaco', 'Courier New', monospace;
            }

            .status {
              background: #d1fae5;
              color: #065f46;
              padding: 12px 16px;
              border-radius: 6px;
              margin-top: 20px;
              font-size: 12px;
              font-weight: 500;
              border: 1px solid #a7f3d0;
            }

            .db-info {
              background: #eff6ff;
              color: #1e40af;
              padding: 12px 16px;
              border-radius: 6px;
              margin-top: 15px;
              font-size: 12px;
              border: 1px solid #bfdbfe;
            }

            .footer {
              margin-top: 30px;
              font-size: 12px;
              color: #bbb;
              border-top: 1px solid #eee;
              padding-top: 20px;
            }

            @media (max-width: 480px) {
              .container {
                padding: 30px 20px;
              }

              .count {
                font-size: 48px;
              }

              .label {
                font-size: 16px;
              }
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <div class="label">Total Page Hits</div>
              <div class="count">${hitCount}</div>
            </div>

            <div class="timestamp">Last hit: ${lastHit}</div>
            <div class="status">✓ Database Connected</div>
            <div class="db-info">Database: ${dbTypeLabel}</div>

            <div class="footer">
              <p>Refresh to increment counter</p>
            </div>
          </div>
        </body>
      </html>
    `);
  } catch (error) {
    logger.error(`Error in main route: ${error.message}`);
    res.status(500).send(`
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <title>Error</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              background: #fee;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              padding: 20px;
            }
            .error-container {
              background: white;
              padding: 40px;
              border-radius: 8px;
              max-width: 500px;
              box-shadow: 0 2px 10px rgba(0,0,0,0.1);
              border-left: 4px solid #dc2626;
            }
            h1 {
              color: #dc2626;
              margin-top: 0;
            }
            .error-message {
              background: #fef2f2;
              padding: 15px;
              border-radius: 4px;
              font-family: monospace;
              font-size: 12px;
              word-break: break-all;
              color: #991b1b;
              margin: 20px 0;
            }
            a {
              color: #667eea;
              text-decoration: none;
            }
            a:hover {
              text-decoration: underline;
            }
          </style>
        </head>
        <body>
          <div class="error-container">
            <h1>Database Connection Error</h1>
            <p>Unable to connect to the database. Please check:</p>
            <ul>
              <li>Database endpoint is correct</li>
              <li>Database credentials are valid</li>
              <li>Security group allows access from EC2</li>
              <li>Database service is running</li>
            </ul>
            <div class="error-message">${error.message}</div>
            <p><a href="/">Try Again</a></p>
          </div>
        </body>
      </html>
    `);
  }
});

/**
 * API endpoint - returns hit data as JSON
 */
router.get('/api/hits', async (req, res) => {
  try {
    const hitData = await db.getHitData();
    res.status(200).json({
      hits: hitData.hit_count,
      lastHit: hitData.last_hit,
      database: config.database.type
    });
  } catch (error) {
    logger.error(`Error in API route: ${error.message}`);
    res.status(500).json({
      error: error.message
    });
  }
});

module.exports = router;
