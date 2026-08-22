/**
 * Simple logging utility
 */

const levels = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3
};

const colors = {
  error: '\x1b[31m',    // Red
  warn: '\x1b[33m',     // Yellow
  info: '\x1b[36m',     // Cyan
  debug: '\x1b[90m',    // Gray
  reset: '\x1b[0m'      // Reset
};

const logLevel = process.env.LOG_LEVEL || 'info';

function formatTime() {
  const now = new Date();
  return now.toISOString();
}

function log(level, message) {
  if (levels[level] <= levels[logLevel]) {
    const timestamp = formatTime();
    const levelStr = level.toUpperCase().padEnd(5);
    const color = colors[level];
    const reset = colors.reset;

    console.log(`${color}[${timestamp}] [${levelStr}]${reset} ${message}`);
  }
}

module.exports = {
  error: (msg) => log('error', msg),
  warn: (msg) => log('warn', msg),
  info: (msg) => log('info', msg),
  debug: (msg) => log('debug', msg)
};
