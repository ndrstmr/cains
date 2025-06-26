// test/integration_test/image_scan_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Aliased
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_functions/firebase_functions.dart';

// Import your app's main entry point and specific screens/widgets needed for finding
import 'package:myapp/main.dart' as app; // Assuming your main.dart has a main()
import 'package:myapp/firebase_options.dart'; // Assuming default Firebase options

// TODO: Replace with your actual test credentials and expected data
const String testEmail = 'testuser@example.com';
const String testPassword = 'password123'; // Ensure this user exists in Auth Emulator

// Helper to configure Firebase emulators
Future<void> configureFirebaseEmulators() async {
  const String host = '10.0.2.2'; // For Android emulator (localhost on host machine)
  // const String host = 'localhost'; // For iOS simulator/local tests

  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await fb_auth.FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Configure to use emulators
    await configureFirebaseEmulators();
  });

  testWidgets('Full Image Scan Flow: Login, Navigate, Pick Image, OCR, Display Words',
      (WidgetTester tester) async {
    // Start the app
    app.main(); // This should call runApp(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle(); // Wait for app to initialize, splash screen, etc.

    // 1. Login Flow
    // Assuming app starts on LoginScreen or redirects there if not logged in
    final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login'); // Using default text from app_en.arb

    // Check if we are on the login screen or need to navigate there from splash/home
    if (tester.any(loginButtonFinder)) {
        // Already on Login screen or similar
    } else {
        // This case implies app might have auto-logged in or is on splash.
        // For a clean test, ideally, sign out first or ensure a fresh state.
        // For now, assuming test starts with a logged-out state or auto-navigates to login.
        // If splash screen leads to login, pumpAndSettle might be enough.
        // If already logged in from a previous run, this test part will behave differently.
        // It's best practice to ensure a clean auth state before each test run.
        // For now, we proceed assuming we need to log in.
        print("Login button not immediately found, assuming app will navigate or test user is logged out.");
        await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait longer for potential navigation
        if (!tester.any(loginButtonFinder)) {
            // If still not found, try navigating explicitly if possible, or fail.
            // This part is highly dependent on the app's initial routing logic.
            // For this test, we'll assume we land on a page with login fields.
        }
    }

    // Enter credentials
    await tester.enterText(find.byWidgetPredicate(
      (widget) => widget is TextFormField && widget.decoration?.labelText == 'Email' // Default from app_en.arb
    ), testEmail);
    await tester.enterText(find.byWidgetPredicate(
      (widget) => widget is TextFormField && widget.decoration?.labelText == 'Password' // Default from app_en.arb
    ), testPassword);
    await tester.pumpAndSettle();

    // Tap login button
    await tester.tap(loginButtonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 3)); // Allow time for Firebase auth and navigation

    // Verify navigation to HomeScreen (e.g., by finding its title or a unique widget)
    expect(find.text('Home'), findsOneWidget); // Default title from app_en.arb for HomeScreen

    // 2. Navigate to ImageScanScreen
    // Assuming 'Scan Text from Image' is the English default from our i18n step
    final imageScanNavButton = find.widgetWithText(ElevatedButton, 'Scan Text from Image');
    expect(imageScanNavButton, findsOneWidget, reason: "Navigation button to Image Scan screen not found on Home screen");
    await tester.tap(imageScanNavButton);
    await tester.pumpAndSettle();

    // Verify navigation to ImageScanScreen
    expect(find.text('Text Recognition'), findsOneWidget); // Default title for ImageScanScreen

    // 3. Simulate Image Selection
    // This is the most challenging part for integration tests with image_picker.
    // image_picker might open a native UI that flutter_test cannot interact with.
    // If this step consistently fails or hangs, consider:
    //    a) Using a test-specific mechanism to inject an image path into the provider.
    //    b) Using a driver like Patrol that can handle native interactions.
    //    c) Focusing the integration test on the flow *after* image selection.
    // For now, we attempt to tap the button.

    final galleryButton = find.widgetWithText(ElevatedButton, 'Gallery');
    expect(galleryButton, findsOneWidget);
    await tester.tap(galleryButton);
    await tester.pumpAndSettle(const Duration(seconds: 5)); // Wait for image picker & potential native UI

    // ** VERY IMPORTANT **: The above tap on "Gallery" will likely NOT work in a standard
    // `flutter test integration_test` environment because it opens a native view.
    // This test will likely fail or hang here without special setup or a different approach.
    // For the purpose of this script, we'll assume a mechanism exists that allows
    // the image picker to return a predefined image in the test environment, or this part is manually handled.
    // If not, the following checks for image display will fail.

    // 4. Check Image Display (assuming image selection was successful somehow)
    // This check assumes the ImageScanProvider's state was updated with an XFile.
    // We need to find the Image widget.
    // This will only pass if an image was "picked" and the provider state updated.
    // Due to the native picker issue, this might require a test-specific way to set the image.
    // For now, let's proceed with a hopeful check:
    // expect(find.byType(Image), findsOneWidget); // This is a weak check.
    // A better check would be if the provider's state reflects an image is selected.
    // Since we can't easily check provider state here without more setup, we rely on UI changes.

    // Let's assume the "Recognize Text" button appears after an image is selected.
    final processButtonFinder = find.widgetWithText(ElevatedButton, 'Recognize Text');
    // This expectation might fail if image picking simulation above doesn't work.
    // We might need to pump longer or use a different strategy.
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Extra time for UI to update after "picking"
    expect(processButtonFinder, findsOneWidget, reason: "Process button not found after attempting to pick image.");

    // 5. Trigger OCR and Check Loading
    await tester.tap(processButtonFinder);
    await tester.pump(); // Start loading

    // Check for loading indicator. There might be two (one general, one on image).
    expect(find.byType(CircularProgressIndicator), findsWidgets, reason: "Loading indicator not found after tapping process.");
    await tester.pumpAndSettle(const Duration(seconds: 5)); // Allow time for (emulated) OCR

    // 6. Check Word Display (Post-OCR)
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: "Loading indicator still present after OCR processing time.");

    // Verify words are displayed. This depends on the emulated function's response.
    // If the emulated function is set up to return specific words for a test image:
    // expect(find.text("YOUR_EXPECTED_WORD_1_FROM_OCR"), findsOneWidget);
    // expect(find.text("YOUR_EXPECTED_WORD_2_FROM_OCR"), findsOneWidget);
    // For now, check if InkWell containers (our word boxes) are present.
    // This is a generic check; specific word checks would be better.
    expect(find.byType(InkWell), findsWidgets, reason: "No InkWell widgets found, meaning no words displayed or test setup issue.");

    // Tap a recognized word (if any found) and check for SnackBar
    if (tester.any(find.byType(InkWell))) {
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle(); // For SnackBar
      // Example: "Tapped: YOUR_WORD"
      expect(find.byType(SnackBar), findsOneWidget, reason: "SnackBar not found after tapping a recognized word.");
    } else {
      print("Skipping word tap test as no InkWell (word) found.");
    }

    // Add a final long settle to observe the screen if running with --debug
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
