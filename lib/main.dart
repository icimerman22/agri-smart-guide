
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Firebase uspješno inicijaliziran.');

    runApp(const AgriSmartGuideApp());

  } on FirebaseException catch (e) {
    debugPrint(
      'Firebase initialization error: ${e.code} - ${e.message}',
    );

    runApp(const FirebaseErrorApp());

  } catch (e, stackTrace) {

    debugPrint('Neočekivana pogreška inicijalizacije: $e');

    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }

    runApp(const FirebaseErrorApp());
  }
}

class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Pogreška pri pokretanju aplikacije',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Firebase servisi nisu dostupni. '
                        'Pokušajte ponovno pokrenuti aplikaciju.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
