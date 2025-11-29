import express from 'express';
import jwt from 'jsonwebtoken';
import morgan from 'morgan';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import Joi from 'joi';

const app = express();
app.use(express.json());
app.use(morgan('dev'));
app.use(cors());

const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    return next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

app.get('/health', (req, res) => res.json({ ok: true }));

// Validation schemas
const dateRangeSchema = Joi.object({
  start: Joi.date().iso().optional(),
  end: Joi.date().iso().optional(),
});

const usersImportSchema = Joi.object({
  users: Joi.array()
    .items(
      Joi.object({
        uid: Joi.string().required(),
        name: Joi.string().required(),
        email: Joi.string().email().required(),
        role: Joi.string().valid('admin', 'user', 'organizer').required(),
        nfc_id: Joi.string().allow('', null),
        qr_hash: Joi.string().allow('', null),
        ble_token: Joi.string().allow('', null),
        wifi_token: Joi.string().allow('', null),
        image_url: Joi.string().uri().allow('', null),
      })
    )
    .min(1)
    .required(),
});

const eventsImportSchema = Joi.object({
  events: Joi.array()
    .items(
      Joi.object({
        event_id: Joi.string().required(),
        title: Joi.string().required(),
        organizer_id: Joi.string().required(),
        start_time: Joi.date().iso().required(),
        end_time: Joi.date().iso().required(),
      })
    )
    .min(1)
    .required(),
});

// Analytics endpoints
app.get('/v1/analytics/summary', auth, (req, res) => {
  res.json({ ok: true, analytics: { users: 0, events: 0, checkins: 0 } });
});

app.post('/v1/analytics/query', auth, (req, res) => {
  const { error, value } = dateRangeSchema.validate(req.body || {});
  if (error) return res.status(400).json({ error: error.message });
  const { start, end } = value;
  res.json({ ok: true, range: { start, end }, results: [] });
});

app.get('/v1/events/:eventId/summary', auth, (req, res) => {
  const { eventId } = req.params;
  res.json({ ok: true, eventId, checkins: 0, uniqueUsers: 0 });
});

// Bulk import endpoints
app.post('/v1/import/users', auth, (req, res) => {
  const { error, value } = usersImportSchema.validate(req.body || {});
  if (error) return res.status(400).json({ error: error.message });
  const count = value.users.length;
  res.json({ ok: true, imported: count });
});

app.post('/v1/import/events', auth, (req, res) => {
  const { error, value } = eventsImportSchema.validate(req.body || {});
  if (error) return res.status(400).json({ error: error.message });
  const count = value.events.length;
  res.json({ ok: true, imported: count });
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Microservice listening on ${port}`));
