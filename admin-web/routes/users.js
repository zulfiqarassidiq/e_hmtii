const express = require('express');
const router  = express.Router();
const { collections } = require('../firebase/admin');
const { requireLogin } = require('../middleware/auth');

// GET /users — daftar semua mahasiswa
router.get('/', requireLogin, async (req, res, next) => {
  try {
    const search = (req.query.search || '').toLowerCase().trim();
    const snap   = await collections.users.orderBy('nama').get();

    let users = snap.docs.map(doc => ({ npm: doc.id, ...doc.data() }));

    if (search) {
      users = users.filter(u =>
        u.nama?.toLowerCase().includes(search) ||
        u.npm?.toLowerCase().includes(search) ||
        u.jurusan?.toLowerCase().includes(search)
      );
    }

    res.render('users/index', {
      title: 'Manajemen User — e-HMTI Admin',
      users,
      search,
    });
  } catch (err) { next(err); }
});

// GET /users/create
router.get('/create', requireLogin, (req, res) => {
  res.render('users/create', {
    title: 'Tambah User — e-HMTI Admin',
    formData: {},
  });
});

// POST /users — simpan user baru
router.post('/', requireLogin, async (req, res, next) => {
  const { npm, nama, jurusan, tahun_masuk, password } = req.body;

  if (!npm || !nama || !jurusan || !tahun_masuk || !password) {
    req.flash('error', 'Semua field wajib diisi.');
    return res.render('users/create', {
      title: 'Tambah User — e-HMTI Admin',
      formData: req.body,
    });
  }

  try {
    const existing = await collections.users.doc(npm).get();
    if (existing.exists) {
      req.flash('error', `NPM ${npm} sudah terdaftar.`);
      return res.render('users/create', {
        title: 'Tambah User — e-HMTI Admin',
        formData: req.body,
      });
    }

    await collections.users.doc(npm).set({
      nama:        nama.trim(),
      jurusan:     jurusan.trim(),
      tahun_masuk: parseInt(tahun_masuk),
      password:    password,
    });

    req.flash('success', `User ${nama} (NPM: ${npm}) berhasil ditambahkan.`);
    res.redirect('/users');
  } catch (err) { next(err); }
});

// GET /users/:npm/edit
router.get('/:npm/edit', requireLogin, async (req, res, next) => {
  try {
    const doc = await collections.users.doc(req.params.npm).get();
    if (!doc.exists) {
      req.flash('error', 'User tidak ditemukan.');
      return res.redirect('/users');
    }
    res.render('users/edit', {
      title: 'Edit User — e-HMTI Admin',
      user: { npm: doc.id, ...doc.data() },
    });
  } catch (err) { next(err); }
});

// PUT /users/:npm — update user
router.put('/:npm', requireLogin, async (req, res, next) => {
  const { nama, jurusan, tahun_masuk, password } = req.body;
  const { npm } = req.params;

  if (!nama || !jurusan || !tahun_masuk) {
    req.flash('error', 'Nama, jurusan, dan tahun masuk wajib diisi.');
    return res.redirect(`/users/${npm}/edit`);
  }

  try {
    const updateData = {
      nama:        nama.trim(),
      jurusan:     jurusan.trim(),
      tahun_masuk: parseInt(tahun_masuk),
    };
    if (password && password.trim() !== '') {
      updateData.password = password.trim();
    }

    await collections.users.doc(npm).update(updateData);
    req.flash('success', `Data user ${nama} berhasil diperbarui.`);
    res.redirect('/users');
  } catch (err) { next(err); }
});

// DELETE /users/:npm
router.delete('/:npm', requireLogin, async (req, res, next) => {
  try {
    const { npm } = req.params;
    const doc = await collections.users.doc(npm).get();
    if (!doc.exists) {
      req.flash('error', 'User tidak ditemukan.');
      return res.redirect('/users');
    }
    await collections.users.doc(npm).delete();
    req.flash('success', `User NPM ${npm} berhasil dihapus.`);
    res.redirect('/users');
  } catch (err) { next(err); }
});

module.exports = router;
