/**
 * Configuration management
 * Loads environment variables and provides app configuration
 */

require('dotenv').config();

const config = {
  app: {
    port: parseInt(process.env.APP_PORT || '8000'),
    env: process.env.NODE_ENV || 'development',
    name: 'hit-counter-app'
  },

  database: {
    type: process.env.DB_TYPE || 'postgres',
    endpoint: process.env.DB_ENDPOINT || 'localhost',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    name: process.env.DB_NAME || 'ha-tt-db',
    port: parseInt(process.env.DB_PORT || '5432')
  },

  logging: {
    level: process.env.LOG_LEVEL || 'info'
  }
};

/**
 * Validate required configuration
 */
function validateConfig() {
  const required = ['DB_ENDPOINT', 'DB_USER', 'DB_PASSWORD'];
  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }

  if (!['postgres', 'mysql'].includes(config.database.type)) {
    throw new Error(`Invalid DB_TYPE: ${config.database.type}. Must be 'postgres' or 'mysql'`);
  }

  return true;
}

module.exports = {
  config,
  validateConfig
};
