# Modular Hit Counter Application

A refactored, maintainable Node.js/Express application with proper separation of concerns.

## 📁 Directory Structure

```
app-structure/
├── index.js              # Main entry point - starts the app
├── config.js             # Configuration management
├── logger.js             # Logging utility
├── db.js                 # Database abstraction layer
├── routes.js             # HTTP route handlers
├── server.js             # Express server setup
├── package.json          # Dependencies
├── .env.example          # Environment variables template
├── userdata-modular.sh   # Optimized EC2 user data script
└── README.md             # This file
```

## 🏗️ Architecture

### Separation of Concerns

Each module has a single responsibility:

- **config.js** - Loads and validates environment variables
- **logger.js** - Provides consistent logging across the app
- **db.js** - Handles all database operations (abstraction layer)
- **routes.js** - Defines HTTP endpoints and handlers
- **server.js** - Creates and configures Express app
- **index.js** - Orchestrates startup and shutdown

### Benefits

✅ **Testable** - Each module can be tested independently
✅ **Maintainable** - Easy to find and update specific functionality
✅ **Scalable** - Easy to add new routes, database operations, or features
✅ **Reusable** - Components can be reused in other projects
✅ **Clear Dependencies** - Easy to see what each module depends on

## 🚀 Quick Start

### Local Development

1. **Clone or setup the application:**
   ```bash
   cd app-structure
   ```

2. **Create .env file:**
   ```bash
   cp .env.example .env
   # Edit .env with your database details
   ```

3. **Install dependencies:**
   ```bash
   npm install
   ```

4. **Start the application:**
   ```bash
   npm start
   ```

5. **Test:**
   - Open http://localhost:8000
   - API: http://localhost:8000/api/hits
   - Health: http://localhost:8000/health

### On AWS EC2

Use the provided user data script:

```bash
# Edit the database configuration in userdata-modular.sh
./userdata-modular.sh
```

Or paste the script content into EC2 Launch Template → User Data field.

## 📋 Module Documentation

### config.js

Loads and validates application configuration from environment variables.

**Exports:**
- `config` - Object with app and database configuration
- `validateConfig()` - Validates required environment variables

**Environment Variables:**
- `APP_PORT` - Application port (default: 8000)
- `NODE_ENV` - Environment (development/production)
- `LOG_LEVEL` - Logging level (error/warn/info/debug)
- `DB_TYPE` - Database type (postgres/mysql)
- `DB_ENDPOINT` - Database host
- `DB_USER` - Database username
- `DB_PASSWORD` - Database password
- `DB_NAME` - Database name
- `DB_PORT` - Database port

**Usage:**
```javascript
const { config, validateConfig } = require('./config');

validateConfig(); // Throws if validation fails
console.log(config.database.type); // 'postgres' or 'mysql'
```

### logger.js

Simple logging utility with color output and log levels.

**Exports:**
- `error(message)` - Log error
- `warn(message)` - Log warning
- `info(message)` - Log info
- `debug(message)` - Log debug

**Usage:**
```javascript
const logger = require('./logger');

logger.info('Application started');
logger.error('Connection failed');
```

### db.js

Database abstraction layer supporting PostgreSQL and MySQL.

**Exports:**
- `initializePool()` - Create connection pool
- `initializeTables()` - Create tables if needed
- `initializeCounter()` - Initialize hit counter to 0
- `healthCheck()` - Verify database connectivity
- `getHitData()` - Get current hit count and timestamp
- `incrementCounter()` - Increment hit count by 1
- `closePool()` - Close database connections

**Usage:**
```javascript
const db = require('./db');

await db.initializePool();
await db.initializeTables();

const data = await db.getHitData();
console.log(`Hits: ${data.hit_count}`);

await db.incrementCounter();
```

### routes.js

Defines HTTP routes and request handlers.

**Routes:**
- `GET /` - Main page with hit counter
- `GET /health` - Health check (database connectivity)
- `GET /api/hits` - JSON API for hit data

**Usage:**
```javascript
const routes = require('./routes');
app.use(routes);
```

### server.js

Creates and configures Express application with middleware.

**Middleware:**
- Body parsing (JSON, URL-encoded)
- Request logging
- Error handling

**Usage:**
```javascript
const createServer = require('./server');
const app = createServer();
app.listen(8000);
```

### index.js

Main entry point that orchestrates application startup.

**Responsibilities:**
- Validate configuration
- Initialize database
- Create server
- Handle graceful shutdown (SIGTERM, SIGINT)

**Usage:**
```bash
node index.js
```

## 🔄 Request Flow

```
Request (HTTP)
    ↓
Nginx (port 80)
    ↓
Express Server (port 8000)
    ↓
routes.js (matches route)
    ↓
Route handler (e.g., GET /)
    ↓
db.js (query database)
    ↓
Database (PostgreSQL or MySQL)
    ↓
Response (HTML/JSON)
```

## 🧪 Testing Locally

### Start the App

**Terminal 1:**
```bash
npm start
```

### Test in Another Terminal

**Health Check:**
```bash
curl http://localhost:8000/health
```

**Get Hit Count:**
```bash
curl http://localhost:8000/api/hits
```

**Browser:**
- Open http://localhost:8000
- Refresh to increment counter

## 📦 Adding Dependencies

### Install a Production Dependency

```bash
npm install new-package
```

### Install a Dev Dependency

```bash
npm install --save-dev new-package
```

### Optional Dependencies (Database Drivers)

Both drivers are optional. The app uses whichever is configured:

```bash
npm install pg          # For PostgreSQL
npm install mysql2      # For MySQL
```

## 🛠️ Extending the Application

### Adding a New Route

1. **Edit routes.js:**
   ```javascript
   router.get('/new-route', async (req, res) => {
     try {
       // Your logic here
       res.json({ message: 'Success' });
     } catch (error) {
       res.status(500).json({ error: error.message });
     }
   });
   ```

### Adding a Database Query

1. **Edit db.js:**
   ```javascript
   async function newQuery() {
     if (config.database.type === 'postgres') {
       const client = await pool.connect();
       try {
         // PostgreSQL query
       } finally {
         client.release();
       }
     } else if (config.database.type === 'mysql') {
       const connection = await pool.getConnection();
       try {
         // MySQL query
       } finally {
         connection.release();
       }
     }
   }
   ```

2. **Export from db.js:**
   ```javascript
   module.exports = {
     // ... existing exports
     newQuery
   };
   ```

### Adding Configuration

1. **Edit .env:**
   ```bash
   NEW_CONFIG_VALUE=something
   ```

2. **Edit config.js:**
   ```javascript
   const config = {
     // ... existing config
     feature: {
       setting: process.env.NEW_CONFIG_VALUE || 'default'
     }
   };
   ```

## 🔒 Security Best Practices

- ✅ Use environment variables for secrets (never commit .env)
- ✅ Validate all input in routes
- ✅ Use parameterized queries (done in db.js)
- ✅ Set strong database passwords
- ✅ Use HTTPS in production (configure reverse proxy/load balancer)
- ✅ Enable database encryption
- ✅ Run app as non-root user (ubuntu on EC2)

## 📊 Performance Considerations

- **Connection Pooling** - Enabled in db.js (10 connections)
- **Request Logging** - Logged for monitoring
- **Error Handling** - Proper error handling prevents crashes
- **Graceful Shutdown** - Closes connections on SIGTERM

## 🚨 Troubleshooting

### Application Won't Start

```bash
# Check logs
npm start

# Check configuration
node -e "const {validateConfig} = require('./config'); validateConfig();"
```

### Database Connection Error

```bash
# Verify database details in .env
cat .env | grep DB_

# Test from app
curl http://localhost:8000/health
```

### Nginx Not Forwarding

```bash
# Check Nginx configuration
sudo nginx -t

# View Nginx logs
sudo tail -f /var/log/nginx/error.log
```

## 📚 Further Reading

- [Express.js Documentation](https://expressjs.com/)
- [PostgreSQL Node Driver](https://node-postgres.com/)
- [MySQL2 Documentation](https://github.com/sidorares/node-mysql2)
- [12 Factor App](https://12factor.net/) - Configuration best practices

## 📄 License

MIT

## 🤝 Contributing

Improvements welcome! Please follow these principles:

- One responsibility per module
- Clear, descriptive names
- Add logging for debugging
- Handle errors gracefully
- Support both PostgreSQL and MySQL
