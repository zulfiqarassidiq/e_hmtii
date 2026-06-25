function requireLogin(req, res, next) {
  if (req.session && req.session.admin) return next();
  req.flash('error', 'Silakan login terlebih dahulu.');
  res.redirect('/login');
}

function redirectIfLoggedIn(req, res, next) {
  if (req.session && req.session.admin) return res.redirect('/dashboard');
  next();
}

module.exports = { requireLogin, redirectIfLoggedIn };
