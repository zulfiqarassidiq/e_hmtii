import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/firestore_setup_banner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _npmCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _jurusanCtrl = TextEditingController();
  final _tahunCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final List<String> _jurusanList = [
    'Teknik Informatika',
    'Sistem Informasi',
  ];
  String? _selectedJurusan;

  @override
  void dispose() {
    _npmCtrl.dispose();
    _namaCtrl.dispose();
    _jurusanCtrl.dispose();
    _tahunCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final user = UserModel(
      npm: _npmCtrl.text.trim(),
      nama: _namaCtrl.text.trim(),
      jurusan: _selectedJurusan ?? _jurusanCtrl.text.trim(),
      tahunMasuk: int.parse(_tahunCtrl.text.trim()),
      password: _passwordCtrl.text,
    );

    final success = await auth.registerUser(user);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context); // kembali ke LoginScreen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registrasi gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Buat Akun Baru',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Isi data diri Anda dengan benar',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 28),

                _buildLabel('NPM'),
                TextFormField(
                  controller: _npmCtrl,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 2021001001',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'NPM wajib diisi';
                    if (v.length < 8) return 'NPM minimal 8 digit';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('Nama Lengkap'),
                TextFormField(
                  controller: _namaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama lengkap',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                _buildLabel('Jurusan'),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedJurusan,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Pilih jurusan',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: _jurusanList
                      .map((j) => DropdownMenuItem(
                          value: j,
                          child: Text(j,
                              style:
                                  const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedJurusan = val),
                  validator: (v) =>
                      v == null ? 'Jurusan wajib dipilih' : null,
                ),
                const SizedBox(height: 16),

                _buildLabel('Tahun Masuk'),
                TextFormField(
                  controller: _tahunCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 2021',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Tahun masuk wajib diisi';
                    final year = int.tryParse(v);
                    if (year == null || year < 2000 || year > 2030) {
                      return 'Tahun tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('Password'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('Konfirmasi Password'),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ulangi password Anda',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                    if (v != _passwordCtrl.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _register,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Daftar Sekarang'),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun?',
                        style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const FirestoreSetupBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600)),
      );
}
