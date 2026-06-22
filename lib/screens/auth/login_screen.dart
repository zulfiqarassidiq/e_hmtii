import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../widgets/firestore_setup_banner.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _npmCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _npmCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.loginUser(_npmCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPassword() {
    final npmCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: npmCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'NPM'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final npm = npmCtrl.text.trim();
                  final newPass = newPassCtrl.text;
                  if (npm.isEmpty || newPass.isEmpty) return;
                  final user =
                      await DatabaseHelper.instance.getUserByNpm(npm);
                  if (!ctx.mounted) return;
                  if (user == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('NPM tidak ditemukan'),
                          backgroundColor: Colors.red),
                    );
                  } else {
                    await DatabaseHelper.instance
                        .updateUserPassword(npm, newPass);
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Password berhasil diubah'),
                            backgroundColor: Colors.green),
                      );
                    }
                  }
                },
                child: const Text('Reset Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Logo / Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/hmti_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, e) => Container(
                            color: Colors.red,
                            child: const Icon(Icons.event,
                                color: Colors.white, size: 44),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('E-HMTI',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Masuk ke akun mahasiswa Anda',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // NPM
                const Text('NPM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _npmCtrl,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan NPM Anda',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'NPM wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // Password
                const Text('Password',
                    style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Masukkan password Anda',
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
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                ),
                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPassword,
                    child: const Text('Lupa Password?',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(height: 16),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 20),

                // Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun?',
                        style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: const Text('Daftar Sekarang',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF333333))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('atau',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider(color: Color(0xFF333333))),
                  ],
                ),
                const SizedBox(height: 16),

                // Firebase connection banner
                const FirestoreSetupBanner(),
                const SizedBox(height: 8),

                // Admin login
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings,
                        color: Colors.red),
                    label: const Text('Masuk sebagai Admin',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
