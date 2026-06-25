const express = require('express');
const router  = express.Router();
const { collections } = require('../firebase/admin');
const { redirectIfLoggedIn } = require('../middleware/auth');

// GET / → redirect ke dashboard atau login
router.get('/', (req, res) => {
  req.session.admin ? res.redirect('/dashboard') : res.redirect('/login');
});

// GET /login
router.get('/login', redirectIfLoggedIn, (req, res) => {
  res.render('login', { title: 'Login Admin — e-HMTI' });
});

// POST /login
router.post('/login', redirectIfLoggedIn, async (req, res) => {
  const { id_admin, password } = req.body;

  if (!id_admin || !password) {
    req.flash('error', 'ID Admin dan password wajib diisi.');
    return res.redirect('/login');
  }

  try {
    const doc = await collections.admins.doc(id_admin).get();

    if (!doc.exists || doc.data().password !== password) {
      req.flash('error', 'ID Admin atau password salah.');
      return res.redirect('/login');
    }

    req.session.admin = { idAdmin: id_admin };
    req.flash('success', `Selamat datang, ${id_admin}!`);
    res.redirect('/dashboard');
  } catch (err) {
    console.error('Login error:', err);
    req.flash('error', 'Terjadi kesalahan server. Coba lagi.');
    res.redirect('/login');
  }
});

// POST /logout
router.post('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/login'));
});

module.exports = router;
