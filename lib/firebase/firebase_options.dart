// Dikonfigurasi dari google-services.json project Firebase "ehmti-1"
// Project Number : 927953225130
// Package Name   : com.himpunan.ehmti

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform belum dikonfigurasi. Tambahkan app Web di Firebase Console.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS belum dikonfigurasi. Tambahkan app iOS di Firebase Console jika diperlukan.',
        );
      default:
        throw UnsupportedError('Platform ini tidak didukung.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyACw9X-AWK9BSnlCKxaQMUjVpl1wdRSSsw',
    appId: '1:927953225130:android:c7af4d33d234b08ea157d3',
    messagingSenderId: '927953225130',
    projectId: 'ehmti-1',
    storageBucket: 'ehmti-1.firebasestorage.app',
  );
}
