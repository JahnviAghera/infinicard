const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { pool } = require('./config/database');
const authRoutes = require('./routes/auth');
const cardsRoutes = require('./routes/cards');
const contactsRoutes = require('./routes/contacts');
const tagsRoutes = require('./routes/tags');

const app = express();
const PORT = process.env.API_PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: 'Too many requests from this IP, please try again later.',
});

app.use('/api/', limiter);

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      success: true,
      message: 'API is healthy',
      timestamp: new Date().toISOString(),
      database: 'connected',
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      message: 'API is unhealthy',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
    });
  }
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/cards', cardsRoutes);
app.use('/api/contacts', contactsRoutes);
app.use('/api/tags', tagsRoutes);
const notificationsRoutes = require('./routes/notifications');
app.use('/api/notifications', notificationsRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Infinicard API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      cards: '/api/cards',
      contacts: '/api/contacts',
      tags: '/api/tags',
    },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.path,
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });
});

// Start server
app.listen(PORT, process.env.API_HOST || '0.0.0.0', () => {
  console.log('\n🚀 Infinicard API Server Started');
  console.log(`📡 Listening on http://localhost:${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`💾 Database: ${process.env.DB_NAME} @ ${process.env.DB_HOST}:${process.env.DB_PORT}`);
  console.log('\n📚 Available endpoints:');
  console.log(`   GET  /health              - Health check`);
  console.log(`   POST /api/auth/register   - Register user`);
  console.log(`   POST /api/auth/login      - Login user`);
  console.log(`   GET  /api/cards           - Get all cards`);
  console.log(`   GET  /api/contacts        - Get all contacts`);
  console.log(`   GET  /api/tags            - Get all tags`);
  console.log('\n✨ Server ready to accept requests\n');
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('\n🛑 SIGTERM received, shutting down gracefully...');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('\n🛑 SIGINT received, shutting down gracefully...');
  await pool.end();
  process.exit(0);
});

module.exports = app;
