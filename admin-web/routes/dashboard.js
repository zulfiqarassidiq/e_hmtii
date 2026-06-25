const express = require('express');
const router  = express.Router();
const { collections } = require('../firebase/admin');
const { requireLogin } = require('../middleware/auth');

router.get('/', requireLogin, async (req, res) => {
  try {
    const [usersSnap, eventsSnap, pendaftaranSnap] = await Promise.all([
      collections.users.get(),
      collections.events.get(),
      collections.pendaftaran.get(),
    ]);

    // Hitung event aktif (tanggal_selesai >= sekarang)
    const now = new Date();
    const activeEvents = eventsSnap.docs.filter(doc => {
      const ts = doc.data().tanggal_selesai;
      if (!ts) return false;
      return ts.toDate() >= now;
    });

    // Total peserta dari counter atomik di koleksi events
    const totalPeserta = eventsSnap.docs.reduce((sum, doc) => {
      return sum + ((doc.data().peserta_count) || 0);
    }, 0);

    // 5 event terbaru
    const recentEvents = eventsSnap.docs
      .sort((a, b) => {
        const ta = a.data().tanggal_mulai?.toDate?.() || new Date(0);
        const tb = b.data().tanggal_mulai?.toDate?.() || new Date(0);
        return tb - ta;
      })
      .slice(0, 5)
      .map(doc => ({ id: doc.id, ...doc.data() }));

    // 5 pendaftar terbaru
    const recentPendaftaran = pendaftaranSnap.docs
      .sort((a, b) => {
        const ta = a.data().tanggal_daftar?.toDate?.() || new Date(0);
        const tb = b.data().tanggal_daftar?.toDate?.() || new Date(0);
        return tb - ta;
      })
      .slice(0, 5)
      .map(doc => ({ id: doc.id, ...doc.data() }));

    res.render('dashboard', {
      title: 'Dashboard — e-HMTI Admin',
      stats: {
        totalUsers:      usersSnap.size,
        totalEvents:     eventsSnap.size,
        activeEvents:    activeEvents.length,
        totalPendaftaran: pendaftaranSnap.size,
        totalPeserta,
      },
      recentEvents,
      recentPendaftaran,
    });
  } catch (err) {
    console.error('Dashboard error:', err);
    next(err);
  }
});

module.exports = router;
