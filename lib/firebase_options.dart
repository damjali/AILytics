import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyABChFzppm8EqOa7jzL5_VTcfD8jQ0DuuY',
      appId: '1:195039407103:android:e3ea178af49f4d6dda55ca',
      messagingSenderId: '195039407103',
      projectId: 'ailytics-b5767',
      storageBucket: 'ailytics-b5767.firebasestorage.app',
    );
  }
}