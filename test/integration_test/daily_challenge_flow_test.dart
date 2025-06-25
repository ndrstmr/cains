import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// Assuming your main app widget is MyApp in main.dart
// You might need to adjust this path.
import 'package:myapp/main.dart' as app;
import 'package:myapp/l10n/app_localizations.dart'; // For finding text based on localization

// IMPORTANT:
// 1. Ensure Firebase Emulators (Auth, Firestore, Functions) are running.
// 2. This test assumes your app's main.dart initializes Firebase and can point to emulators.
//    A common way is to check for a Dart-define like `FIREBASE_EMULATOR=true`.
//    Example main.dart modification:
//    ```dart
//    const bool useEmulator = bool.fromEnvironment('FIREBASE_EMULATOR');
//    if (useEmulator) {
//      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
//      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
//      // For functions, FunctionsService needs to point to emulator URL
//      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001); // If using FirebaseFunctions SDK directly
//    }
//    ```
// 3. You might need a separate main_test.dart entry point for integration tests
//    if your main.dart has platform-specific code not suitable for testing.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase App if not already done by the app's main.
    // This is often needed here for integration tests.
    // This setup should ideally mirror your app's actual Firebase initialization,
    // including pointing to emulators.
    await Firebase.initializeApp();

    const bool useEmulator = bool.fromEnvironment('FIREBASE_EMULATOR', defaultValue: false);
    if (!useEmulator) {
        // This is a fallback, ideally the app itself handles this in its main based on the dart-define.
        // If this code runs, it means the app's main() didn't set up emulators.
        // For this test to reliably work against emulators, the app's Firebase instances
        // (Auth, Firestore, Functions via FunctionsService) MUST be pointing to the emulators.
        debugPrint(
          "Integration Test: FIREBASE_EMULATOR flag not explicitly true. " +
          "Ensure app is configured to use emulators for this test."
        );
        // Attempt to configure them here if not done by the app's main()
        // This is a bit risky as the app might have already initialized them.
        try {
          await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
          FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
          // Note: FunctionsService URL needs to be set to emulator,
          // this direct FirebaseFunctions config is if you use that SDK directly for callables.
          // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
        } catch (e) {
          debugPrint("Error trying to set emulators in test: $e. App should handle this.");
        }
    }
     // Initialize App Check for emulators if you use it
    try {
      await FirebaseAppCheck.instance.activate(
        webRecaptchaSiteKey: 'recaptcha-v3-site-key', // Not used for emulator but required by activate
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } catch (e) {
      debugPrint("AppCheck activation failed (may be normal if not configured for project): $e");
    }
  });

  testWidgets('Daily Challenge Flow - Generate and Display', (WidgetTester tester) async {
    // Start the app.
    // Assuming app.main() initializes MyApp and all necessary providers.
    app.main();
    await tester.pumpAndSettle(); // Wait for app to initialize, Firebase connect, etc.

    final String uniqueEmail = 'testuser_${DateTime.now().millisecondsSinceEpoch}@example.com';
    const String password = 'password123';

    // --- 1. Registration/Login ---
    // This part depends heavily on your app's auth screen structure.
    // Replace with actual widget finders and interactions for your app.
    // Example: Find "Register" button, tap it.
    // await tester.tap(find.text('Register')); // Or find.byKey(Key('registerButton'))
    // await tester.pumpAndSettle();

    // Example: Find email/password fields, enter text.
    // await tester.enterText(find.byKey(const Key('registerEmailField')), uniqueEmail);
    // await tester.enterText(find.byKey(const Key('registerPasswordField')), password);
    // await tester.tap(find.byKey(const Key('registerSubmitButton')));
    // await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for registration and auto-login

    // For simplicity, let's assume direct Firebase Auth operations for setup if UI is complex.
    // In a real scenario, you'd drive the UI.
    User? user;
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: uniqueEmail,
        password: password,
      );
      user = userCredential.user;
      debugPrint("Integration Test: User registered and signed in: ${user?.uid}");
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        debugPrint("Integration Test: User already exists, signing in instead.");
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: uniqueEmail,
          password: password,
        );
        user = userCredential.user;
        debugPrint("Integration Test: User signed in: ${user?.uid}");
      } else {
        debugPrint("Integration Test: Error during auth setup: $e");
        rethrow;
      }
    }
    expect(user, isNotNull, reason: "User should be signed in for the test.");
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Allow time for auth state to propagate

    // --- 2. Navigate to HomeScreen (if not already there after login) ---
    // This depends on your app's routing. If login navigates to Home, this might not be needed.
    // await tester.tap(find.text('Go to Home')); // Or appropriate navigation action
    // await tester.pumpAndSettle();

    // Verify we are on HomeScreen (e.g., by finding its title or a unique widget)
    // Assuming AppLocalizations is available for the current context after pumpAndSettle
    // This might require pumping a specific MaterialApp with localizations delegates if app.main() doesn't set it up for tests.
    // For now, we assume default English or the first supported locale.
    // A better way is to have a common test helper that pumps MyApp with necessary setup.

    // Hack: get localizations. This is not ideal in tests.
    // You'd normally find widgets by text using the English/default string.
    // This is just to make it work if localizations are tricky in test environment.
    final BuildContext context = tester.element(find.byType(MaterialApp)); // Find MaterialApp
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    expect(find.text(localizations.homePageTitle), findsOneWidget, reason: "Should be on HomeScreen");

    // --- 3. Daily Challenge Display and Generation ---
    // Initially, there might be no challenge, or a button to get it.
    // The HomeScreen's build method now tries to auto-fetch if currentChallenge is null.

    // Wait for potential auto-fetch to complete or for the UI to settle.
    // The auto-fetch logic uses addPostFrameCallback and invalidate, so pumpAndSettle should cover it.
    debugPrint("Integration Test: Waiting for HomeScreen to settle and potentially auto-fetch challenge...");
    await tester.pumpAndSettle(const Duration(seconds: 5)); // Increased timeout for function call

    // Check if the challenge card is now displayed.
    // If the function call was successful, currentChallenge should update.
    // We look for text that appears on the challenge card.
    // The exact text depends on the randomly generated challenge.
    // So, we look for generic elements of the challenge card.

    // Option 1: Challenge loaded automatically or button was implicitly handled by auto-fetch
    // We expect to find elements of the _DailyChallengeSection
    final Finder challengeTitleFinder = find.byWidgetPredicate(
      (Widget widget) => widget is Text && widget.style?.fontSize == Theme.of(context).textTheme.headlineSmall?.fontSize && widget.data!.contains("Daily Challenge:"),
      description: 'Text widget for challenge title',
    );
    final Finder startChallengeButtonFinder = find.widgetWithText(ElevatedButton, localizations.startChallengeButtonLabel);

    // It might take a few pumps for the state to update after the function call.
    await tester.pumpAndSettle(const Duration(seconds: 3));


    if (tester.any(startChallengeButtonFinder)) {
      debugPrint("Integration Test: Challenge seems to be displayed.");
      expect(challengeTitleFinder, findsOneWidget, reason: "Challenge title should be displayed");
      expect(startChallengeButtonFinder, findsOneWidget, reason: "'Start Challenge' button should be visible");
    } else {
      // Option 2: If auto-fetch didn't complete or if we need to press a button
      debugPrint("Integration Test: Challenge not auto-displayed, looking for 'Get Today's Challenge' button.");
      final Finder getChallengeButton = find.widgetWithText(ElevatedButton, localizations.getTodaysChallengeButtonLabel);
      if (tester.any(getChallengeButton)) {
         await tester.tap(getChallengeButton);
         debugPrint("Integration Test: Tapped 'Get Today's Challenge' button.");
         await tester.pumpAndSettle(const Duration(seconds: 5)); // Wait for function call and UI update

         expect(challengeTitleFinder, findsOneWidget, reason: "Challenge title should be displayed after button tap");
         expect(startChallengeButtonFinder, findsOneWidget, reason: "'Start Challenge' button should be visible after button tap");
      } else {
        // If neither the challenge nor the button is found, there might be an issue or an error state.
        // Check for error message from _DailyChallengeSection
        final Finder retryButtonFinder = find.widgetWithText(ElevatedButton, localizations.retryButtonLabel);
        if (tester.any(retryButtonFinder)) {
            debugPrint("Integration Test: Challenge fetch resulted in an error state. Tapping retry.");
            await tester.tap(retryButtonFinder);
            await tester.pumpAndSettle(const Duration(seconds: 5));

            expect(challengeTitleFinder, findsOneWidget, reason: "Challenge title should be displayed after retry");
            expect(startChallengeButtonFinder, findsOneWidget, reason: "'Start Challenge' button should be visible after retry");
        } else {
            fail("Integration Test: Daily challenge section not found in expected state (no challenge, no get button, no retry button).");
        }
      }
    }

    // --- 4. (Optional) Interact with "Start Challenge" ---
    // This is a placeholder interaction as the actual navigation/action is not fully defined.
    if(tester.any(startChallengeButtonFinder)){
        await tester.tap(startChallengeButtonFinder);
        await tester.pumpAndSettle(); // Wait for SnackBar or navigation
        // Verify expected outcome, e.g., SnackBar message or navigation to WordGridScreen
        // For now, we assume it shows a SnackBar as per current HomeScreen implementation
        expect(find.byType(SnackBar), findsOneWidget, reason: "SnackBar should appear when 'Start Challenge' is tapped");
        debugPrint("Integration Test: 'Start Challenge' button tapped, SnackBar likely shown.");
    } else {
        debugPrint("Integration Test: 'Start Challenge' button not found for interaction test.");
    }


    // --- Cleanup: Sign out user (optional, but good practice) ---
    await FirebaseAuth.instance.signOut();
    debugPrint("Integration Test: User signed out.");
    await tester.pumpAndSettle();

    // Test completed
    debugPrint("Integration Test: Daily Challenge Flow test completed successfully.");
  });
}
