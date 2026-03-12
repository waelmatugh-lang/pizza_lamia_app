import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB9fJ0RDjkF95y2EwB_TinhwaYHmbznWyw',
    appId: '1:171001688842:web:a57f94f9fe4aad3e63c0f3',
    messagingSenderId: '171001688842',
    projectId: 'pizza-lamia-app',
    authDomain: 'pizza-lamia-app.firebaseapp.com',
    storageBucket: 'pizza-lamia-app.firebasestorage.app',
    measurementId: 'G-ZDFG95KZZC',
  );
}
