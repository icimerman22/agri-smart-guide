// Test prihvatljivosti za priču "Zaključavanje računa nakon 5 neuspjelih
// prijava" (docs/xp-radionica/zakljucavanje-racuna.md).
import 'package:agri_smart_guide/app/app.dart';
import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/data/lockout_auth_service.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/auth/presentation/auth_keys.dart';
import 'package:agri_smart_guide/features/auth/presentation/login_screen.dart';
import 'package:agri_smart_guide/features/home/presentation/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_helpers.dart';
import '../../../support/fake_auth_service.dart';
import '../../../support/fake_profile_repository.dart';

const lockedMessage =
    'Račun je privremeno zaključan nakon 5 neuspjelih pokušaja. '
    'Pokušajte ponovno za 15 minuta.';

void main() {
  late FakeAuthService firebase;

  Future<void> pumpLoginWithLockout(WidgetTester tester) async {
    firebase = FakeAuthService();
    await tester.pumpWidget(
      AgriSmartGuideApp(
        initialRoute: AppRoutes.login,
        authService: LockoutAuthService(firebase),
        profileRepository: FakeProfileRepository(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitLogin(WidgetTester tester, String password) async {
    await enterAuthText(tester, AuthKeys.loginEmail, 'ana@opg.hr');
    await enterAuthText(tester, AuthKeys.loginPassword, password);
    await tapAuthButton(tester, AuthKeys.loginSubmit);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Zadano: 4 neuspjele prijave; Kada: peti put unesem pogrešnu lozinku; '
    'Tada: vidim poruku o zaključanom računu',
    (tester) async {
      await pumpLoginWithLockout(tester);
      firebase.signInError = const AuthException('invalid-credential');

      for (var i = 0; i < 4; i++) {
        await submitLogin(tester, 'pogresna');
        expect(
          find.text('Neispravna e-mail adresa ili lozinka.'),
          findsOneWidget,
        );
      }

      await submitLogin(tester, 'pogresna');

      expect(find.text(lockedMessage), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Zadano: račun je zaključan; Kada: unesem točnu lozinku; '
    'Tada: prijava je odbijena i ostajem na prijavi',
    (tester) async {
      await pumpLoginWithLockout(tester);
      firebase.signInError = const AuthException('invalid-credential');
      for (var i = 0; i < 5; i++) {
        await submitLogin(tester, 'pogresna');
      }

      firebase.signInError = null;
      await submitLogin(tester, 'tocna123');

      expect(find.text(lockedMessage), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(firebase.signInCalls, 5);
    },
  );
}
