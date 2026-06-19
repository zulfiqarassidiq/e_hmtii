import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_service.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  AdminModel? _currentAdmin;
  bool _isLoading = false;
  String? _errorMessage;

  // null  = belum dicek / berhasil konek
  // kode  = FirebaseException.code (e.g. 'unavailable', 'permission-denied')
  String? _firestoreStatus;
  bool _checkingConnection = true;

  UserModel? get currentUser => _currentUser;
  AdminModel? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUserLoggedIn => _currentUser != null;
  bool get isAdminLoggedIn => _currentAdmin != null;
  String? get firestoreStatus => _firestoreStatus;
  bool get checkingConnection => _checkingConnection;
  bool get isFirestoreOk => !_checkingConnection && _firestoreStatus == null;

  AuthProvider() {
    _runConnectionCheck();
  }

  Future<void> _runConnectionCheck() async {
    _checkingConnection = true;
    notifyListeners();
    _firestoreStatus = await FirebaseService.instance.testConnection();
    _checkingConnection = false;
    notifyListeners();
  }

  Future<void> retryConnection() async {
    await _runConnectionCheck();
  }

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

  String _parseFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
        return 'Firestore tidak bisa dijangkau.\n'
            'Kemungkinan Firestore Database belum diaktifkan di Firebase Console, '
            'atau Security Rules memblokir akses.';
      case 'permission-denied':
        return 'Akses ditolak. Periksa Firestore Security Rules di Firebase Console.';
      case 'not-found':
        return 'Data tidak ditemukan.';
      case 'already-exists':
        return 'Data sudah ada.';
      case 'deadline-exceeded':
        return 'Koneksi timeout. Coba lagi.';
      case 'unauthenticated':
        return 'Sesi tidak valid. Silakan login ulang.';
      case 'no-app':
        return 'Firebase belum dikonfigurasi. Jalankan flutterfire configure.';
      default:
        return 'Firebase error [${e.code}]: ${e.message}';
    }
  }

  // ─── LOGIN USER ──────────────────────────────────────────────────────────────

  Future<bool> loginUser(String npm, String password) async {
    _setLoading(true);
    _setError(null);
    bool result = false;
    try {
      final user = await FirebaseService.instance.loginUser(npm, password);
      if (user != null) {
        _currentUser = user;
        result = true;
      } else {
        _setError('NPM atau password salah.');
      }
    } on FirebaseException catch (e) {
      _setError(_parseFirebaseError(e));
    } catch (e) {
      // Menangkap SEMUA throwable (termasuk Error, bukan hanya Exception)
      // sehingga _isLoading di blok finally PASTI ter-reset ke false.
      _setError('Terjadi kesalahan: $e');
      debugPrint('loginUser error: $e');
    } finally {
      // SELALU dijalankan — tombol pasti kembali ke state normal
      _setLoading(false);
    }
    return result;
  }

  // ─── REGISTER USER ───────────────────────────────────────────────────────────

  Future<bool> registerUser(UserModel user) async {
    _setLoading(true);
    _setError(null);
    bool result = false;
    try {
      await FirebaseService.instance.registerUser(user);
      result = true;
    } on FirebaseException catch (e) {
      _setError(_parseFirebaseError(e));
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      debugPrint('registerUser error: $e');
    } finally {
      _setLoading(false);
    }
    return result;
  }

  // ─── LOGIN ADMIN ─────────────────────────────────────────────────────────────

  Future<bool> loginAdmin(String idAdmin, String password) async {
    _setLoading(true);
    _setError(null);
    bool result = false;
    try {
      final admin = await FirebaseService.instance.loginAdmin(idAdmin, password);
      if (admin != null) {
        _currentAdmin = admin;
        result = true;
      } else {
        _setError('ID Admin atau password salah.');
      }
    } on FirebaseException catch (e) {
      _setError(_parseFirebaseError(e));
    } catch (e) {
      _setError('Terjadi kesalahan: $e');
      debugPrint('loginAdmin error: $e');
    } finally {
      _setLoading(false);
    }
    return result;
  }

  // ─── REFRESH USER ────────────────────────────────────────────────────────────

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    try {
      final updated =
          await FirebaseService.instance.getUserByNpm(_currentUser!.npm);
      if (updated != null) {
        _currentUser = updated;
        notifyListeners();
      }
    } catch (_) {
      // Refresh gagal (offline/error) — tetap pakai data sesi saat ini
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
