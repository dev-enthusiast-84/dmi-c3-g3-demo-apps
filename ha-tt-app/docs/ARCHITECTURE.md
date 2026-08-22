# Architecture & Best Practices Guide

## 🎯 Overview

The original monolithic user data script has been refactored into a modular, maintainable application structure following best practices for production Node.js applications.

## 📈 Improvements

### Before (Monolithic)
```
userdata-mysql.sh / userdata-postgres.sh
├── All code inline (1000+ lines)
├── Mixed concerns (config, logging, DB, routes)
├── Difficult to test
├── Hard to maintain
└── Hard to extend
```

### After (Modular)
```
app-structure/
├── config.js          (Configuration)
├── logger.js          (Logging)
├── db.js              (Database)
├── routes.js          (HTTP endpoints)
├── server.js          (Express setup)
├── index.js           (Orchestration)
├── package.json       (Dependencies)
└── .env.example       (Configuration template)
```

## ✅ Principles Applied

### 1. Single Responsibility Principle (SRP)

Each module does one thing well:

| Module | Responsibility |
|--------|-----------------|
| config.js | Load and validate environment variables |
| logger.js | Output formatted logs |
| db.js | Manage database operations |
| routes.js | Handle HTTP requests |
| server.js | Configure Express middleware |
| index.js | Orchestrate startup |

**Benefit:** Easy to modify one aspect without affecting others.

### 2. Separation of Concerns

```
HTTP Request → Routing → Business Logic → Database → Response
     ↓            ↓            ↓            ↓          ↓
  routes.js    routes.js      db.js       db.js    JSON/HTML
```

**Benefit:** Clear flow, easy to debug, easy to test.

### 3. Configuration Management

**Before:** Database config hardcoded in user data script
**After:** Environment variables + validation

```javascript
// config.js
const config = {
  database: {
    type: process.env.DB_TYPE,
    endpoint: process.env.DB_ENDPOINT,
    // ...
  }
};

validateConfig(); // Fails fast if config is missing
```

**Benefit:** Same code works in dev, staging, and production.

### 4. Database Abstraction Layer

**Before:** Database operations scattered throughout code
**After:** All DB operations in one module

```javascript
// db.js - Single source of truth
await db.incrementCounter();
await db.getHitData();
await db.healthCheck();
```

**Benefit:** Easy to switch databases or add caching layer.

### 5. Logging Strategy

**Before:** `console.log()` scattered throughout
**After:** Centralized logger with levels

```javascript
// Any module
logger.error('Something failed');
logger.info('Application started');
logger.debug('Detailed info');
```

**Benefit:** Consistent format, easier to parse, can be routed to cloud logging.

### 6. Graceful Shutdown

**Before:** Application killed immediately
**After:** Closes connections cleanly

```javascript
// index.js
process.on('SIGTERM', () => {
  logger.info('Shutting down gracefully');
  server.close(() => {
    db.closePool(); // Clean up
    process.exit(0);
  });
});
```

**Benefit:** No lost database connections, no corrupted transactions.

## 🔄 Data Flow

### Request Flow

```
1. HTTP Request (port 80)
   ↓
2. Nginx reverse proxy
   ↓
3. Express (port 8000)
   ↓
4. Router (routes.js)
   ↓
5. Route Handler
   ↓
6. Database (db.js)
   ↓
7. Connection Pool
   ↓
8. PostgreSQL/MySQL
   ↓
9. Response (HTML/JSON)
   ↓
10. HTTP Response (port 80)
```

### Initialization Flow

```
1. node index.js
   ↓
2. validateConfig() - Check environment variables
   ↓
3. initializePool() - Create database connections
   ↓
4. initializeTables() - Create tables if needed
   ↓
5. initializeCounter() - Set hit counter to 0 if empty
   ↓
6. createServer() - Start Express server
   ↓
7. app.listen(8000) - Accept requests
   ↓
8. Ready to handle requests
```

## 🧪 Testing Strategy

### Unit Testing (Each Module)

```javascript
// Test config.js
const { config } = require('./config');
assert.equal(config.app.port, 8000);

// Test logger.js
logger.info('Test message'); // Should not throw

// Test db.js
const data = await db.getHitData();
assert.ok(data.hit_count);
```

### Integration Testing

```javascript
// Test full flow
await db.incrementCounter();
const data = await db.getHitData();
assert.ok(data.hit_count > 0);
```

### End-to-End Testing

```bash
# Test from browser or curl
curl http://localhost:8000/api/hits
```

## 📊 Performance Optimization

### Connection Pooling

```javascript
// db.js
const pool = new Pool({
  connectionLimit: 10,  // Max connections
  queueLimit: 0         // Max queue size
});
```

**Impact:** Reuses connections instead of creating new ones per request.

### Response Caching

Could be added:

```javascript
// routes.js
router.get('/api/hits', cache('5 minutes'), async (req, res) => {
  // Only queries DB every 5 minutes
});
```

### Database Indexing

```sql
-- On database server
CREATE INDEX idx_hits_id ON hits(id);
```

## 🔒 Security Hardening

### 1. Environment Variables

```bash
# ✅ Good - in .env (never commit)
DB_PASSWORD=super-secret-password

# ❌ Bad - hardcoded in code
password: 'super-secret-password'
```

### 2. Input Validation

```javascript
// routes.js - Validate all input
if (!req.query.userId || typeof req.query.userId !== 'number') {
  return res.status(400).json({ error: 'Invalid input' });
}
```

### 3. SQL Injection Prevention

```javascript
// ✅ Good - Parameterized query
await client.query('SELECT * FROM hits WHERE id = $1', [hitId]);

// ❌ Bad - String concatenation
await client.query(`SELECT * FROM hits WHERE id = ${hitId}`);
```

Already implemented in db.js.

### 4. Error Handling

```javascript
// ❌ Bad - leaks error details
res.json(error); // Shows database structure, credentials, etc.

// ✅ Good - generic error message
res.status(500).json({ error: 'Internal Server Error' });
```

### 5. HTTPS/TLS

```nginx
# Configure in Nginx/reverse proxy
listen 443 ssl;
ssl_certificate /path/to/cert.pem;
ssl_certificate_key /path/to/key.pem;
```

## 📈 Scalability Considerations

### Horizontal Scaling

Current setup supports multiple instances:

```
Load Balancer
├── EC2 Instance 1 (app + Nginx)
├── EC2 Instance 2 (app + Nginx)
└── EC2 Instance 3 (app + Nginx)
    ↓
Shared RDS Database
```

Database abstraction layer makes this easy.

### Vertical Scaling

Change instance type:
- t3.micro → t3.small → t3.medium → etc.

Application code doesn't need changes.

### Database Optimization

```sql
-- Add more connections if needed
-- Increase work_mem for PostgreSQL
-- Increase buffer pool for MySQL
-- Add read replicas for heavy load
```

## 🚀 Deployment Scenarios

### Scenario 1: Single Instance (Current)

```
EC2 (Ubuntu)
├── Node.js App
├── Nginx (reverse proxy)
└── Database (RDS)
```

Use `userdata-modular.sh` script.

### Scenario 2: Load Balanced

```
Load Balancer (ALB)
├── EC2 #1 (Node.js + Nginx)
├── EC2 #2 (Node.js + Nginx)
└── EC2 #3 (Node.js + Nginx)
    ↓
RDS Database (Multi-AZ)
```

Use Auto Scaling Group with modular app code.

### Scenario 3: Containerized

```
ECS Cluster
├── Container #1 (Node.js app from app-structure/)
├── Container #2 (Node.js app from app-structure/)
└── Container #3 (Node.js app from app-structure/)
    ↓
RDS Database
```

Dockerfile would use this app structure.

## 📋 Monitoring & Logging

### Application Logs

```bash
# View logs on EC2
sudo journalctl -u app -f
sudo journalctl -u app -n 100

# Each log has consistent format:
# [2026-08-21T10:30:45.123Z] [INFO ] Database initialized
```

### Health Endpoint

```bash
curl http://localhost:8000/health
# Returns: { status: 'healthy', db: 'postgres', ... }
```

### Metrics to Monitor

- Request count per minute
- Response time
- Error rate
- Database connection count
- CPU and memory usage

### CloudWatch Integration

```bash
# On EC2, install CloudWatch agent
# Point logs to CloudWatch
# Set alarms for high error rate, high latency, etc.
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: cd app-structure && npm install
      - name: Run tests
        run: npm test
      - name: Deploy to AWS
        run: ./deploy.sh
```

## 📚 Development Workflow

### Local Development

```bash
# Clone repository
git clone <repo> && cd ha-tt-app/app-structure

# Setup
cp .env.example .env
npm install

# Develop
npm start

# Make changes, test in browser

# Commit and push
git add .
git commit -m "Feature: add new endpoint"
git push
```

### Staging Deployment

```bash
# Push to staging branch
git push origin feature-branch

# CI/CD builds and deploys to staging
# Test in staging environment
# Merge to main when ready
```

### Production Deployment

```bash
# Merge to main
git merge feature-branch

# CI/CD builds and deploys to production
# Monitor logs and metrics
```

## 🎓 Best Practices Summary

| Practice | Before | After | Benefit |
|----------|--------|-------|---------|
| **Configuration** | Hardcoded | Environment vars | Environment-agnostic |
| **Logging** | console.log | Structured logger | Parseable logs |
| **Database** | Inline queries | Abstraction layer | Easy to change DB |
| **Error Handling** | Catches missing | Validates input | Fails fast |
| **Code Organization** | Monolithic | Modular | Easy to maintain |
| **Testability** | Hard to test | Unit testable | Better quality |
| **Scalability** | Single instance | Load balancer ready | Scale horizontally |
| **Shutdown** | Immediate kill | Graceful shutdown | No data loss |

## 🚀 Next Steps

1. **Deploy modular app** - Use `userdata-modular.sh` on EC2
2. **Add tests** - Create Jest test suite
3. **Setup monitoring** - CloudWatch alarms and dashboards
4. **Document API** - Add Swagger/OpenAPI documentation
5. **Add authentication** - If needed for API endpoints
6. **Setup CI/CD** - GitHub Actions or CodePipeline
7. **Scale** - Add load balancer and auto-scaling

## 📞 Support

For questions or improvements:
- Check README.md in app-structure/
- Review code comments in each module
- Check logs for error messages
- Monitor /health endpoint
