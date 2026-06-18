import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/admin_model.dart';
import '../database/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  AdminModel? _currentAdmin;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  AdminModel? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUserLoggedIn => _currentUser != null;
  bool get isAdminLoggedIn => _currentAdmin != null;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── LOGIN USER ──────────────────────────────────────────────────────────────

  Future<bool> loginUser(String npm, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await DatabaseHelper.instance.loginUser(npm, password);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _setError('NPM atau password salah.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan: $e');
      _setLoading(false);
      return false;
    }
  }

  // ─── REGISTER USER ───────────────────────────────────────────────────────────

  Future<bool> registerUser(UserModel user) async {
    _setLoading(true);
    _setError(null);
    try {
      final existing = await DatabaseHelper.instance.getUserByNpm(user.npm);
      if (existing != null) {
        _setError('NPM sudah terdaftar.');
        _setLoading(false);
        return false;
      }
      await DatabaseHelper.instance.insertUser(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Registrasi gagal: $e');
      _setLoading(false);
      return false;
    }
  }

  // ─── LOGIN ADMIN ─────────────────────────────────────────────────────────────

  Future<bool> loginAdmin(String idAdmin, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final admin = await DatabaseHelper.instance.loginAdmin(idAdmin, password);
      if (admin != null) {
        _currentAdmin = admin;
        _setLoading(false);
        return true;
      } else {
        _setError('ID Admin atau password salah.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan: $e');
      _setLoading(false);
      return false;
    }
  }

  // ─── REFRESH USER ────────────────────────────────────────────────────────────

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final updated =
        await DatabaseHelper.instance.getUserByNpm(_currentUser!.npm);
    if (updated != null) {
      _currentUser = updated;
      notifyListeners();
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────────────

  void logoutUser() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void logoutAdmin() {
    _currentAdmin = null;
    _errorMessage = null;
    notifyListeners();
  }
}
