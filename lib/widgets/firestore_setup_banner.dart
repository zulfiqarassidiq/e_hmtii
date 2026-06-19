import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Banner yang muncul di screen auth ketika Firestore belum dapat dijangkau.
/// Hilang otomatis setelah koneksi berhasil.
class FirestoreSetupBanner extends StatelessWidget {
  const FirestoreSetupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.checkingConnection) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: const Color(0xFF1A1A1A),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Mengecek koneksi Firebase...',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (auth.isFirestoreOk) return const SizedBox.shrink();

    final isPermissionDenied = auth.firestoreStatus == 'permission-denied';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1000),
        border: Border.all(color: Colors.orange.shade800),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade400, size: 18),
              const SizedBox(width: 8),
              Text(
                isPermissionDenied
                    ? 'Security Rules Memblokir Akses'
                    : 'Firestore Belum Diaktifkan',
                style: TextStyle(
                  color: Colors.orange.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!isPermissionDenied) ...[
            _step('1',
                'Buka console.firebase.google.com → project ehmti-1'),
            _step('2', 'Klik Build → Firestore Database'),
            _step('3', 'Klik "Create database"'),
            _step('4', 'Pilih "Start in test mode" → Next → Enable'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1A0D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade900),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setelah Firestore aktif, buat dokumen admin:',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Collection: admins\n'
                    'Document ID: admin001\n'
                    'Field: password = "admin123"',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _step('1',
                'Buka Firebase Console → Firestore Database → Rules'),
            _step('2', 'Ganti rules menjadi:'),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'allow read, write: if true;',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
            _step('3', 'Klik "Publish"'),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().retryConnection(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 8, top: 1),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
