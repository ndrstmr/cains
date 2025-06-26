// test/screens/image_scan_screen_test.dart
import 'dart:io'; // For File
import 'dart:typed_data'; // For Uint8List
import 'dart:ui' as ui; // For ui.Rect

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:myapp/main.dart'; // To access MyApp for pumpWidget with ProviderScope
import 'package:myapp/providers/image_scan_provider.dart';
import 'package:myapp/screens/image_scan_screen.dart';
import 'package:myapp/services/functions_service.dart' show RecognizedWord; // For RecognizedWord model
import 'package:myapp/l10n/app_localizations.dart'; // For AppLocalizations

// Mocks
// We need to mock ImageScanNotifier
class MockImageScanNotifier extends StateNotifier<ImageScanState>
    implements ImageScanNotifier {
  MockImageScanNotifier(ImageScanState initialState) : super(initialState);

  // Keep track of method calls if needed for verification
  int pickImageCallCount = 0;
  ImageSource? lastImageSource;
  @override
  Future<void> pickImage(ImageSource source) async {
    pickImageCallCount++;
    lastImageSource = source;
    // Simulate state changes or set state directly for testing UI reactions
  }

  int processImageCallCount = 0;
  @override
  Future<void> processImage() async {
    processImageCallCount++;
  }

  int clearErrorCallCount = 0;
  @override
  void clearError() {
    clearErrorCallCount++;
  }

  int resetStateCallCount = 0;
  @override
  void resetState() {
    resetStateCallCount++;
     state = ImageScanState.initial(); // Simulate reset
  }

  // Allow tests to directly manipulate the state for UI testing
  voidsetState(ImageScanState newState) {
    state = newState;
  }
}

// Fake ImagePickerPlatform (can be copied or imported if made common)
class FakeImagePickerPlatformInWidgetTest extends Fake implements ImagePickerPlatform {
  XFile? _nextXFile;
  Exception? _nextException;
  bool _cancelled = false;

  void setNextXFile(XFile file) {
    _nextXFile = file;
    _nextException = null;
    _cancelled = false;
  }
   void setCancelled(bool cancelled) {
    _cancelled = cancelled;
    _nextXFile = null;
    _nextException = null;
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (_cancelled) return null;
    if (_nextException != null) throw _nextException!;
    return _nextXFile;
  }
   @override
  Future<LostDataResponse> getLostData() async {
    return LostDataResponse.empty();
  }
}


Widget createTestableWidget(Widget child, MockImageScanNotifier mockNotifier) {
  return ProviderScope(
    overrides: [
      imageScanProvider.overrideWithValue(mockNotifier),
    ],
    child: MaterialApp( // MaterialApp needed for ScaffoldMessenger, Navigator, Themes
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
      // If ImageScanScreen uses Navigator.push for something, add routes here or mock Navigator
    ),
  );
}


void main() {
  late FakeImagePickerPlatformInWidgetTest fakeImagePickerPlatform;
  late MockImageScanNotifier mockNotifier;

  setUp(() {
    fakeImagePickerPlatform = FakeImagePickerPlatformInWidgetTest();
    ImagePickerPlatform.instance = fakeImagePickerPlatform;
    // Initial state for the notifier
    mockNotifier = MockImageScanNotifier(ImageScanState.initial());
  });

  // Helper to pump the widget with everything needed
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const ImageScanScreen(), mockNotifier));
    await tester.pumpAndSettle(); // Process any immediate frame changes or listeners
  }

  group('ImageScanScreen Widget Tests', () {
    testWidgets('Initial state UI elements are present', (WidgetTester tester) async {
      await pumpScreen(tester);

      // Check for AppBar title (using default value as localizations might not be fully ready in test like this)
      expect(find.text('Text Recognition'), findsOneWidget); // Default value of imageScanScreenTitle

      // Check for buttons
      expect(find.widgetWithText(ElevatedButton, 'Gallery'), findsOneWidget); // Default for pickFromGalleryButton
      expect(find.widgetWithText(ElevatedButton, 'Camera'), findsOneWidget); // Default for takePictureButton

      // Check "Recognize Text" button is NOT present
      expect(find.widgetWithText(ElevatedButton, 'Recognize Text'), findsNothing);

      // Check for placeholder text
      expect(find.text('Select an image or take a photo to start.'), findsOneWidget); // Default for selectImagePrompt

      // Check no image is displayed (Image.file should not be found)
      expect(find.byType(Image), findsNothing); // More specific: expect(find.byWidgetPredicate((widget) => widget is Image && widget.image is FileImage), findsNothing);

      // Check no loading indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Picking an image updates UI and shows process button', (WidgetTester tester) async {
      // Create a dummy XFile - ensure it has a valid path for FileImage
      // For widget tests, the actual file content doesn't matter as much as the path.
      // The `path` needs to be something `File(path)` can be constructed with, even if it doesn't exist.
      final testImagePath = 'test_resources/test_image.png';
      // Ensure the test environment can handle this path for FileImage, or use a memory image if easier.
      // For simplicity, assuming FileImage will construct with a non-null path.
      final testXFile = XFile(testImagePath, mimeType: 'image/png', bytes: Uint8List.fromList([1,2,3])); // Add dummy bytes

      fakeImagePickerPlatform.setNextXFile(testXFile);

      // Simulate the notifier's state change after picking an image
      // This is because the widget test doesn't run the real notifier's pickImage method.
      // We are testing the UI's reaction to the state.
      mockNotifier.voidSetState(ImageScanState(
        selectedImageFile: testXFile,
        status: ImageScanStatus.imagePicked,
        imageSize: const ui.Size(100, 100) // Provide a mock image size
      ));

      await pumpScreen(tester);

      // Tap the gallery button - this would trigger the *real* notifier if not mocked
      // Since we mock the notifier, we directly set its state to simulate image picked.
      // If we wanted to test the notifier interaction:
      // await tester.tap(find.widgetWithText(ElevatedButton, 'Gallery'));
      // await tester.pumpAndSettle();
      // verify(mockNotifier.pickImage(ImageSource.gallery)).called(1); // This would be on a true mock

      // Verify image is displayed
      // This requires Image.file to be found. The path of XFile is used.
      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<FileImage>());
      expect((imageWidget.image as FileImage).file.path, testImagePath);


      // Verify "Recognize Text" button is present
      expect(find.widgetWithText(ElevatedButton, 'Recognize Text'), findsOneWidget);

      // Verify placeholder text is gone
      expect(find.text('Select an image or take a photo to start.'), findsNothing);
    });

    testWidgets('Loading indicator shows during OCR processing', (WidgetTester tester) async {
      final testXFile = XFile('test_path.png');
      mockNotifier.voidSetState(ImageScanState(
        selectedImageFile: testXFile, // Need an image to be in processing state
        status: ImageScanStatus.processingOcr,
        imageSize: const ui.Size(100,100) // Need image size for layout builder
      ));
      await pumpScreen(tester);

      // The screen has two potential loading indicators. One on the image, one at the bottom.
      // The one on the image is inside the LayoutBuilder, the other is in the main column.
      expect(find.byType(CircularProgressIndicator), findsWidgets); // Could be one or two
    });

    testWidgets('Displays recognized words on OCR success', (WidgetTester tester) async {
      final testXFile = XFile('test_path.png');
      final words = [
        RecognizedWord(text: 'Hello', bounds: const ui.Rect.fromLTWH(10, 10, 50, 20)),
        RecognizedWord(text: 'World', bounds: const ui.Rect.fromLTWH(70, 10, 50, 20)),
      ];
      mockNotifier.voidSetState(ImageScanState(
        selectedImageFile: testXFile,
        status: ImageScanStatus.ocrSuccess,
        recognizedWords: words,
        imageSize: const ui.Size(200, 100) // Original image size
      ));
      await pumpScreen(tester);

      expect(find.byType(Image), findsOneWidget); // Image is shown

      // Check for the InkWell containers that represent the words
      // This count assumes each word results in one InkWell.
      expect(find.byType(InkWell), findsNWidgets(words.length));

      // Tapping a word (example: the first one)
      // We need to find the specific InkWell. This is tricky without unique keys.
      // For now, tapping the first InkWell found.
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle(); // For SnackBar to appear and settle

      // Verify SnackBar with word text (using default value for the key)
      expect(find.text('Tapped: Hello'), findsOneWidget);
    });

    testWidgets('Shows error SnackBar on OCR error', (WidgetTester tester) async {
      final errorMessage = 'Test OCR Error';
      // Initial state with no error
      mockNotifier.voidSetState(ImageScanState(
        status: ImageScanStatus.imagePicked, // Some state before error
        selectedImageFile: XFile('dummy.png')
      ));
      await pumpScreen(tester);

      // Simulate error state by directly setting it and notifying listeners
      mockNotifier.voidSetState(ImageScanState(
        status: ImageScanStatus.ocrError,
        errorMessage: errorMessage,
        selectedImageFile: XFile('dummy.png') // Keep image selected
      ));
      await tester.pumpAndSettle(); // Pump for ref.listen to trigger and SnackBar

      expect(find.text(errorMessage), findsOneWidget); // SnackBar content

      // Verify it's a SnackBar (more robustly, check for SnackBar widget itself)
      expect(find.byType(SnackBar), findsOneWidget);
    });

  });
}
