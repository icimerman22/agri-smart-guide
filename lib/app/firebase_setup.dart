import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

const useAuthEmulator = bool.fromEnvironment('USE_AUTH_EMULATOR');
const authEmulatorProject = 'demo-agri-smart-guide';

Future<FirebaseAuth>? _initialization;

Future<FirebaseAuth> initializeFirebase() => _initialization ??= _initialize();

Future<FirebaseAuth> _initialize() async {
  late FirebaseApp firebaseApp;

  if (useAuthEmulator) {
    if (kReleaseMode) {
      throw StateError(
        'Auth emulator is only available in non-release builds.',
      );
    }
    firebaseApp = await Firebase.initializeApp(
      name: 'auth-integration',
      options: const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:1234567890:android:1234567890abcdef',
        messagingSenderId: '1234567890',
        projectId: authEmulatorProject,
      ),
    );
    await FirebaseAuth.instanceFor(app: firebaseApp).useAuthEmulator(
      const String.fromEnvironment(
        'AUTH_EMULATOR_HOST',
        defaultValue: '10.0.2.2',
      ),
      9099,
    );
  } else {
    firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final auth = FirebaseAuth.instanceFor(app: firebaseApp);
  await auth.authStateChanges().first;
  return auth;
}
