const express = require('express');
const router  = express.Router();
const { collections, admin } = require('../firebase/admin');
const { requireLogin } = require('../middleware/auth');

// GET /events
router.get('/', requireLogin, async (req, res, next) => {
  try {
    const snap   = await collections.events.orderBy('tanggal_mulai', 'desc').get();
    const events = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.render('events/index', { title: 'Manajemen Event — e-HMTI Admin', events });
  } catch (err) { next(err); }
});

// GET /events/create
router.get('/create', requireLogin, (req, res) => {
  res.render('events/create', { title: 'Tambah Event — e-HMTI Admin', formData: {} });
});

// POST /events
router.post('/', requireLogin, async (req, res, next) => {
  const { nama_event, tanggal_mulai, tanggal_selesai, kuota, lokasi, foto, deskripsi } = req.body;

  if (!nama_event || !tanggal_mulai || !tanggal_selesai || !kuota || !lokasi) {
    req.flash('error', 'Nama event, tanggal, kuota, dan lokasi wajib diisi.');
    return res.render('events/create', { title: 'Tambah Event — e-HMTI Admin', formData: req.body });
  }

  try {
    await collections.events.add({
      nama_event:       nama_event.trim(),
      tanggal_mulai:    admin.firestore.Timestamp.fromDate(new Date(tanggal_mulai)),
      tanggal_selesai:  admin.firestore.Timestamp.fromDate(new Date(tanggal_selesai)),
      kuota:            parseInt(kuota),
      lokasi:           lokasi.trim(),
      foto:             foto?.trim() || '',
      deskripsi:        deskripsi?.trim() || '',
      peserta_count:    0,
    });

    req.flash('success', `Event "${nama_event}" berhasil ditambahkan.`);
    res.redirect('/events');
  } catch (err) { next(err); }
});

// GET /events/:id/edit
router.get('/:id/edit', requireLogin, async (req, res, next) => {
  try {
    const doc = await collections.events.doc(req.params.id).get();
    if (!doc.exists) {
      req.flash('error', 'Event tidak ditemukan.');
      return res.redirect('/events');
    }
    const data    = doc.data();
    const toLocal = ts => ts?.toDate?.()?.toISOString?.().slice(0, 16) || '';
    res.render('events/edit', {
      title: 'Edit Event — e-HMTI Admin',
      event: {
        id:              doc.id,
        ...data,
        tanggal_mulai:   toLocal(data.tanggal_mulai),
        tanggal_selesai: toLocal(data.tanggal_selesai),
      },
    });
  } catch (err) { next(err); }
});

// PUT /events/:id
router.put('/:id', requireLogin, async (req, res, next) => {
  const { nama_event, tanggal_mulai, tanggal_selesai, kuota, lokasi, foto, deskripsi } = req.body;

  if (!nama_event || !tanggal_mulai || !tanggal_selesai || !kuota || !lokasi) {
    req.flash('error', 'Nama event, tanggal, kuota, dan lokasi wajib diisi.');
    return res.redirect(`/events/${req.params.id}/edit`);
  }

  try {
    await collections.events.doc(req.params.id).update({
      nama_event:      nama_event.trim(),
      tanggal_mulai:   admin.firestore.Timestamp.fromDate(new Date(tanggal_mulai)),
      tanggal_selesai: admin.firestore.Timestamp.fromDate(new Date(tanggal_selesai)),
      kuota:           parseInt(kuota),
      lokasi:          lokasi.trim(),
      foto:            foto?.trim() || '',
      deskripsi:       deskripsi?.trim() || '',
    });

    req.flash('success', `Event "${nama_event}" berhasil diperbarui.`);
    res.redirect('/events');
  } catch (err) { next(err); }
});

// DELETE /events/:id — juga hapus semua pendaftaran terkait
router.delete('/:id', requireLogin, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = collections.events.firestore;

    const batch   = db.batch();
    const regSnap = await collections.pendaftaran.where('id_event', '==', id).get();
    regSnap.docs.forEach(doc => batch.delete(doc.ref));
    batch.delete(collections.events.doc(id));
    await batch.commit();

    req.flash('success', 'Event dan seluruh pendaftarannya berhasil dihapus.');
    res.redirect('/events');
  } catch (err) { next(err); }
});

// GET /events/:id/peserta — daftar peserta suatu event
router.get('/:id/peserta', requireLogin, async (req, res, next) => {
  try {
    const [eventDoc, pesertaSnap] = await Promise.all([
      collections.events.doc(req.params.id).get(),
      collections.pendaftaran.where('id_event', '==', req.params.id).get(),
    ]);

    if (!eventDoc.exists) {
      req.flash('error', 'Event tidak ditemukan.');
      return res.redirect('/events');
    }

    const peserta = pesertaSnap.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => (a.nama || '').localeCompare(b.nama || ''));

    res.render('events/peserta', {
      title: `Peserta — ${eventDoc.data().nama_event}`,
      event: { id: eventDoc.id, ...eventDoc.data() },
      peserta,
    });
  } catch (err) { next(err); }
});

module.exports = router;
