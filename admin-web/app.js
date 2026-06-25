require('dotenv').config();
const express = require('express');
const session = require('express-session');
const flash = require('connect-flash');
const cookieParser = require('cookie-parser');
const methodOverride = require('method-override');
const path = require('path');

const authRoutes      = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const usersRoutes     = require('./routes/users');
const eventsRoutes    = require('./routes/events');

const app  = express();
const PORT = process.env.PORT || 3000;

// ── View engine ──────────────────────────────────────────────────────────────
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// ── Static files ─────────────────────────────────────────────────────────────
app.use(express.static(path.join(__dirname, 'public')));

// ── Body parsers ─────────────────────────────────────────────────────────────
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(cookieParser());

// ── Method override (support PUT/DELETE dari HTML form) ───────────────────────
app.use(methodOverride('_method'));

// ── Session ───────────────────────────────────────────────────────────────────
app.use(session({
  secret: process.env.SESSION_SECRET || 'ehmti_secret_key',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 8 * 60 * 60 * 1000 }, // 8 jam
}));

// ── Flash messages ────────────────────────────────────────────────────────────
app.use(flash());

// ── Global locals untuk semua views ──────────────────────────────────────────
app.use((req, res, next) => {
  res.locals.success = req.flash('success');
  res.locals.error   = req.flash('error');
  res.locals.admin   = req.session.admin || null;
  next();
});

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/',         authRoutes);
app.use('/dashboard', dashboardRoutes);
app.use('/users',     usersRoutes);
app.use('/events',    eventsRoutes);

// ── 404 handler ───────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).render('404', { title: 'Halaman Tidak Ditemukan' });
});

// ── Error handler ─────────────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).render('error', { title: 'Server Error', message: err.message });
});

app.listen(PORT, () => {
  console.log(`✅  e-HMTI Admin Web berjalan di http://localhost:${PORT}`);
});
