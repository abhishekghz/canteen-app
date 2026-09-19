// Firebase configuration for the Canteen app.
//
// Web is fully configured below. For Android/iOS, register those apps in the
// Firebase console (or run `flutterfire configure`) and fill in their appIds.
// These values are not secret — they ship in every client app.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured => true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is only configured for Web/Android/iOS. '
          'Run `flutterfire configure` to add this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBZDB7Fv_lmqSgxg5FO4w1zFmSn1PN8oks',
    authDomain: 'canteen-app-72a86.firebaseapp.com',
    projectId: 'canteen-app-72a86',
    storageBucket: 'canteen-app-72a86.firebasestorage.app',
    messagingSenderId: '473825971838',
    appId: '1:473825971838:web:2435a6c366f9b3830c922f',
    measurementId: 'G-HSW877XN54',
  );

  // Android/iOS reuse the same project. Replace `appId` with the platform app's
  // ID from the Firebase console (Project settings → Your apps) when you add
  // the Android (package com.canteen.canteen_app) and iOS (bundle
  // com.canteen.canteenApp) apps. Until then these use the web appId, which is
  // fine for a first run but should be replaced for production.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZDB7Fv_lmqSgxg5FO4w1zFmSn1PN8oks',
    appId: '1:473825971838:web:2435a6c366f9b3830c922f',
    messagingSenderId: '473825971838',
    projectId: 'canteen-app-72a86',
    storageBucket: 'canteen-app-72a86.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZDB7Fv_lmqSgxg5FO4w1zFmSn1PN8oks',
    appId: '1:473825971838:web:2435a6c366f9b3830c922f',
    messagingSenderId: '473825971838',
    projectId: 'canteen-app-72a86',
    storageBucket: 'canteen-app-72a86.firebasestorage.app',
    iosBundleId: 'com.canteen.canteenApp',
  );
}
