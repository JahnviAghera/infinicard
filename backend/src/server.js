const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const { pool } = require('./config/database');
const authRoutes = require('./routes/auth');
const cardsRoutes = require('./routes/cards');
const contactsRoutes = require('./routes/contacts');
const tagsRoutes = require('./routes/tags');
const discoverRoutes = require('./routes/discover');

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
  // Attempt a quick DB health check but don't let DB unavailability make the whole API return 503.
  // Instead return a 200 with a degraded status so orchestrators know the app is up while DB may be down.
  let dbStatus = 'unknown';
  let dbError = null;
  try {
    await pool.query('SELECT 1');
    dbStatus = 'connected';
  } catch (error) {
    dbStatus = 'disconnected';
    dbError = error && error.message ? error.message : String(error);
    // Log at warn level so it's visible in logs but doesn't crash the process
    console.warn('Health check: database unavailable:', dbError);
  }

  const degraded = dbStatus !== 'connected';

  const payload = {
    success: !degraded,
    message: degraded ? 'API running (degraded) - database unavailable' : 'API is healthy',
    timestamp: new Date().toISOString(),
    database: dbStatus,
  };

  // Only include DB error details in development to avoid leaking internals in production
  if (process.env.NODE_ENV === 'development' && dbError) payload.dbError = dbError;

  // Always return 200 so external health checks know the service process is up. Use the payload to indicate degradation.
  res.status(200).json(payload);
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/cards', cardsRoutes);
app.use('/api/contacts', contactsRoutes);
app.use('/api/tags', tagsRoutes);
app.use('/api/discover', discoverRoutes);
const notificationsRoutes = require('./routes/notifications');
app.use('/api/notifications', notificationsRoutes);

// Mail helper (development)
const { sendTestEmail } = require('./mail');

// Simple test route to send email (development only)
app.post('/api/mail/send-test', async (req, res) => {
  try {
    const { to, subject, text } = req.body || {};
    if (!to) return res.status(400).json({ success: false, message: 'Missing `to` in body' });

    const info = await sendTestEmail(to, subject || 'Test Email', text || 'This is a test email from Infinicard');
    res.json({ success: true, info });
  } catch (err) {
    console.error('Error sending test email:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Lightweight health/ping for mail routes - helps verify routes registered without sending email
app.get('/api/mail/ping', (req, res) => {
  try {
    res.json({ success: true, message: 'Mail route registered', env: process.env.SMTP_HOST || 'not-set' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Serve a small web page to test sending emails in the browser (development)
app.get('/mail-test', (req, res) => {
  try {
    res.sendFile(path.join(__dirname, '..', 'public', 'mail-test.html'));
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Dev endpoints to send welcome and OTP emails
app.post('/api/mail/send-welcome', async (req, res) => {
  try {
    const { to, name, extra } = req.body || {};
    if (!to) return res.status(400).json({ success: false, message: 'Missing `to` in body' });
    const { sendWelcomeEmail } = require('./mail');
    const info = await sendWelcomeEmail(to, name || '', extra || '');
    res.json({ success: true, info });
  } catch (err) {
    console.error('Error sending welcome email:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/mail/send-otp', async (req, res) => {
  try {
    const { to, otp, purpose } = req.body || {};
    if (!to || !otp) return res.status(400).json({ success: false, message: 'Missing `to` or `otp` in body' });
    const { sendOtpEmail } = require('./mail');
    const info = await sendOtpEmail(to, otp, purpose || 'verification');
    res.json({ success: true, info });
  } catch (err) {
    console.error('Error sending otp email:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Serve admin pages for welcome/otp
app.get('/mail-send-welcome', (req, res) => {
  try {
    res.sendFile(path.join(__dirname, '..', 'public', 'mail-send-welcome.html'));
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/mail-send-otp', (req, res) => {
  try {
    res.sendFile(path.join(__dirname, '..', 'public', 'mail-send-otp.html'));
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

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
