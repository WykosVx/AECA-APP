import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCm6fwaLMKax9eDxgPaJ3_fsckwrqKBlSY', 
    appId: '1:544838952602:android:3d08dcb9c4afedc6556123',
    messagingSenderId: '544838952602',
    projectId: 'aecaapp-27c08',
    storageBucket: 'aecaapp-27c08.appspot.com',
  );
}