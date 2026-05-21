import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDefG-iCidPgYGCw5b-vjRwjcwLI9eZaAg',
    appId: '1:364000454014:web:7cbf57e86bdd0ea58e7f2f',
    messagingSenderId: '364000454014',
    projectId: 'jp-style-lounge-studio',
    authDomain: 'jp-style-lounge-studio.firebaseapp.com',
    storageBucket: 'jp-style-lounge-studio.firebasestorage.app',
    measurementId: 'G-0T1LYKVME7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB69D8ln1VYm48CkD2_B5ZJ4Iaixej-y3s',
    appId: '1:364000454014:android:743ee9dc5512bac48e7f2f',
    messagingSenderId: '364000454014',
    projectId: 'jp-style-lounge-studio',
    storageBucket: 'jp-style-lounge-studio.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0WxEMuTvGbBCE9BWprSa4_L6jx1IhrQ0',
    appId: '1:364000454014:ios:08298941491dbb448e7f2f',
    messagingSenderId: '364000454014',
    projectId: 'jp-style-lounge-studio',
    storageBucket: 'jp-style-lounge-studio.firebasestorage.app',
    iosBundleId: 'app.jpstyleloungestudio.jp_style_lounge_studio',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA0WxEMuTvGbBCE9BWprSa4_L6jx1IhrQ0',
    appId: '1:364000454014:ios:08298941491dbb448e7f2f',
    messagingSenderId: '364000454014',
    projectId: 'jp-style-lounge-studio',
    storageBucket: 'jp-style-lounge-studio.firebasestorage.app',
    iosBundleId: 'app.jpstyleloungestudio.jp_style_lounge_studio',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDefG-iCidPgYGCw5b-vjRwjcwLI9eZaAg',
    appId: '1:364000454014:web:0e94b6653eb6928c8e7f2f',
    messagingSenderId: '364000454014',
    projectId: 'jp-style-lounge-studio',
    authDomain: 'jp-style-lounge-studio.firebaseapp.com',
    storageBucket: 'jp-style-lounge-studio.firebasestorage.app',
    measurementId: 'G-RWRTNDW464',
  );

}