import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDPIb4oARA3c8J3-0CB4Lj8US9YD0fDgo',
    appId: '1:1093357938546:android:945510e290f6aa140cdfeb',
    messagingSenderId: '1093357938546',
    projectId: 'fir-24245',
    storageBucket: 'fir-24245.appspot.com',
    androidClientId: "236905844516-kbs6ttfnr7a5dk96rt3abc2lap1gpiq4.apps.googleusercontent.com"
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDPIb4oARA3c8J3-0CB4Lj8US9YD0fDgo',
    appId: '1:236905844516:ios:eea4dfbbaef45a434c2db1',
    messagingSenderId: '236905844516',
    projectId: 'fir-24245',
    storageBucket: 'fir-24245.appspot.com',
    iosClientId:
        '236905844516-erg6ea0qja14itlio3nk0kdoa0gmdqbr.apps.googleusercontent.com',
    iosBundleId: 'com.firebase',
  );
}
