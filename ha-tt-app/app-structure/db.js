/**
 * Database connection and initialization
 * Supports both PostgreSQL and MySQL
 */

const { config } = require('./config');
const logger = require('./logger');

let pool = null;

/**
 * Initialize database connection pool
 */
async function initializePool() {
  try {
    if (config.database.type === 'postgres') {
      const { Pool } = require('pg');
      pool = new Pool({
        host: config.database.endpoint,
        user: config.database.user,
        password: config.database.password,
        database: config.database.name,
        port: config.database.port
      });

      logger.info(`PostgreSQL pool created (${config.database.endpoint}:${config.database.port})`);
    } else if (config.database.type === 'mysql') {
      const mysql = require('mysql2/promise');
      pool = mysql.createPool({
        host: config.database.endpoint,
        user: config.database.user,
        password: config.database.password,
        database: config.database.name,
        port: config.database.port,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0
      });

      logger.info(`MySQL pool created (${config.database.endpoint}:${config.database.port})`);
    }

    return pool;
  } catch (error) {
    logger.error(`Failed to create database pool: ${error.message}`);
    throw error;
  }
}

/**
 * Create tables if they don't exist
 */
async function initializeTables() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        await client.query(`
          CREATE TABLE IF NOT EXISTS hits (
            id SERIAL PRIMARY KEY,
            hit_count INT DEFAULT 0,
            last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        await connection.execute(`
          CREATE TABLE IF NOT EXISTS hits (
            id INT AUTO_INCREMENT PRIMARY KEY,
            hit_count INT DEFAULT 0,
            last_hit TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
          )
        `);
      } finally {
        connection.release();
      }
    }

    logger.info('Hits table initialized');
  } catch (error) {
    logger.error(`Failed to initialize tables: ${error.message}`);
    throw error;
  }
}

/**
 * Initialize hit counter to 0 if empty
 */
async function initializeCounter() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT COUNT(*) as count FROM hits');
        if (parseInt(result.rows[0].count) === 0) {
          await client.query('INSERT INTO hits (hit_count) VALUES (0)');
          logger.info('Hit counter initialized to 0');
        }
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        const [rows] = await connection.execute('SELECT COUNT(*) as count FROM hits');
        if (rows[0].count === 0) {
          await connection.execute('INSERT INTO hits (hit_count) VALUES (0)');
          logger.info('Hit counter initialized to 0');
        }
      } finally {
        connection.release();
      }
    }
  } catch (error) {
    logger.error(`Failed to initialize counter: ${error.message}`);
    throw error;
  }
}

/**
 * Health check - verify database connectivity
 */
async function healthCheck() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        await client.query('SELECT NOW()');
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        await connection.ping();
      } finally {
        connection.release();
      }
    }
    return true;
  } catch (error) {
    logger.error(`Health check failed: ${error.message}`);
    return false;
  }
}

/**
 * Get current hit count and last hit timestamp
 */
async function getHitData() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        const result = await client.query(
          'SELECT hit_count, last_hit FROM hits WHERE id = 1'
        );
        return result.rows[0];
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        const [rows] = await connection.execute(
          'SELECT hit_count, last_hit FROM hits WHERE id = 1'
        );
        return rows[0];
      } finally {
        connection.release();
      }
    }
  } catch (error) {
    logger.error(`Failed to get hit data: ${error.message}`);
    throw error;
  }
}

/**
 * Increment hit counter by 1
 */
async function incrementCounter() {
  try {
    if (config.database.type === 'postgres') {
      const client = await pool.connect();
      try {
        await client.query(
          'UPDATE hits SET hit_count = hit_count + 1, last_hit = CURRENT_TIMESTAMP WHERE id = 1'
        );
      } finally {
        client.release();
      }
    } else if (config.database.type === 'mysql') {
      const connection = await pool.getConnection();
      try {
        await connection.execute(
          'UPDATE hits SET hit_count = hit_count + 1 WHERE id = 1'
        );
      } finally {
        connection.release();
      }
    }
  } catch (error) {
    logger.error(`Failed to increment counter: ${error.message}`);
    throw error;
  }
}

/**
 * Close database connections
 */
async function closePool() {
  try {
    if (config.database.type === 'postgres' && pool) {
      await pool.end();
      logger.info('PostgreSQL pool closed');
    } else if (config.database.type === 'mysql' && pool) {
      await pool.end();
      logger.info('MySQL pool closed');
    }
  } catch (error) {
    logger.error(`Error closing pool: ${error.message}`);
  }
}

module.exports = {
  initializePool,
  initializeTables,
  initializeCounter,
  healthCheck,
  getHitData,
  incrementCounter,
  closePool,
  getPool: () => pool
};
