import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// A stub file to fix the compiler error.
// TO FIX PROPERLY: Run `flutterfire configure` in your terminal to overwrite this
// with your real Firebase project credentials.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'dummy-api-key-run-flutterfire-configure',
      appId: '1:1234567890:web:abcdef123456',
      messagingSenderId: '1234567890',
      projectId: 'dummy-project-id',
      authDomain: 'dummy-project-id.firebaseapp.com',
      storageBucket: 'dummy-project-id.appspot.com',
    );
  }
}
