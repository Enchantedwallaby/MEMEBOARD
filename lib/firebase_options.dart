import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      case TargetPlatform.macOS: return ios;
      case TargetPlatform.windows: return windows;
      case TargetPlatform.linux: return linux;
      default: throw UnsupportedError('Platform not supported');
    }
  }

  static const web = FirebaseOptions(
    apiKey: "AIzaSyBskaeIQKfEPI1_6aOTVep4yUbQf4b8OUc",
    authDomain: "memeboard-app.firebaseapp.com",
    projectId: "memeboard-app",
    storageBucket: "memeboard-app.appspot.com",
    messagingSenderId: "139598946029",
    appId: "1:139598946029:web:cc1317e842105788b3f61f",
    measurementId: "G-0RCNSG92Z8",
  );
  static const android = FirebaseOptions(
    apiKey: "AIzaSyCrySTwZ2VCLNAjOpYvj56A-3pd1rfGoRE",
    appId: "1:139598946029:android:af9c03db1875f4e2b3f61f",
    messagingSenderId: "139598946029",
    projectId: "memeboard-app",
    storageBucket: "memeboard-app.appspot.com",
  );
  static const ios = FirebaseOptions(
    apiKey: "AIzaSyCrySTwZ2VCLNAjOpYvj56A-3pd1rfGoRE",
    appId: "1:139598946029:ios:4e657205f3ed2137b3f61f",
    messagingSenderId: "139598946029",
    projectId: "memeboard-app",
    storageBucket: "memeboard-app.appspot.com",
    iosClientId: "139598946029-2tv5vi0ikni3oqvlddrd1e86o8gp9iho.apps.googleusercontent.com",
    iosBundleId: "com.example.memeboard",
  );
  static const windows = android;
  static const linux = android;
}
