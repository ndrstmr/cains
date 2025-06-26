// test/providers/image_scan_provider_test.dart
import 'dart:typed_data';
import 'dart:ui' as ui; // For ui.Size

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'package:myapp/providers/image_scan_provider.dart';
import 'package:myapp/services/functions_service.dart';

// Mocks
@GenerateMocks([FunctionsService, ImagePicker, ui.Codec, ui.FrameInfo, ui.Image])
import 'image_scan_provider_test.mocks.dart';

// Fake ImagePickerPlatform to control image picking results
class FakeImagePickerPlatform extends Fake implements ImagePickerPlatform {
  XFile? _nextXFile;
  Exception? _nextException;
  bool _cancelled = false;

  void setNextXFile(XFile file) {
    _nextXFile = file;
    _nextException = null;
    _cancelled = false;
  }

  void setNextException(Exception exception) {
    _nextXFile = null;
    _nextException = exception;
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

  // Also mock lost data retrieval if your provider uses it, otherwise not strictly needed.
  @override
  Future<LostDataResponse> getLostData() async {
    return LostDataResponse.empty();
  }
}


void main() {
  late MockFunctionsService mockFunctionsService;
  late FakeImagePickerPlatform fakeImagePickerPlatform;
  late ImageScanNotifier notifier;
  late ProviderContainer container;

  // Mock ui.Image related objects
  late MockCodec mockUiCodec;
  late MockFrameInfo mockUiFrameInfo;
  late MockImage mockUiImage;

  setUp(() {
    mockFunctionsService = MockFunctionsService();
    fakeImagePickerPlatform = FakeImagePickerPlatform();
    ImagePickerPlatform.instance = fakeImagePickerPlatform; // Inject the fake platform

    mockUiCodec = MockCodec();
    mockUiFrameInfo = MockFrameInfo();
    mockUiImage = MockImage();

    // Default stubs for ui.Image loading
    when(mockUiImage.width).thenReturn(100); // Default mock image width
    when(mockUiImage.height).thenReturn(100); // Default mock image height
    when(mockUiFrameInfo.image).thenReturn(mockUiImage);
    // `ui.instantiateImageCodec` is a top-level function. Mocking it directly is hard.
    // The provider's image loading logic might need to be refactored to allow injection
    // of this decoding step, or we accept this part is not fully unit tested.
    // For now, we focus on the XFile being passed around.
    // A simpler approach for testing the image size part would be to mock the `pickedFile.readAsBytes()`
    // and then provide a mock for `ui.instantiateImageCodec` if possible, or test this part via widget/integration tests.

    // Setup ProviderContainer for testing Riverpod providers
    container = ProviderContainer(
      overrides: [
        // Override functionsServiceProvider if it's used by imageScanProvider to get FunctionsService
        // Assuming imageScanProvider takes FunctionsService and ImagePicker directly
        // For `imageScanProvider` which instantiates ImagePicker() directly:
        // We've set ImagePickerPlatform.instance, so new ImagePicker() will use our fake.
      ],
    );

    // Instantiate the notifier, providing the mocked FunctionsService and a real ImagePicker
    // (which will use our FakeImagePickerPlatform)
    notifier = ImageScanNotifier(mockFunctionsService, ImagePicker());
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is correct', () {
    expect(notifier.debugState.status, ImageScanStatus.initial);
    expect(notifier.debugState.selectedImageFile, isNull);
    expect(notifier.debugState.recognizedWords, isEmpty);
    expect(notifier.debugState.errorMessage, isNull);
    expect(notifier.debugState.imageSize, isNull);
  });

  group('pickImage', () {
    final testFile = XFile('dummy_path/test_image.jpg', mimeType: 'image/jpeg', bytes: Uint8List(0));
    // Note: ui.instantiateImageCodec will be called with bytes from testFile.readAsBytes()
    // Mocking this interaction is complex at unit level without refactoring the provider.
    // We will assume for this unit test that if an XFile is returned, the image size logic inside
    // the provider is called, but we won't verify the exact ui.Size here due to mocking complexity
    // of top-level `ui.instantiateImageCodec`.

    test('successfully picks an image and updates state', () async {
      fakeImagePickerPlatform.setNextXFile(testFile);
      // To properly test image size, we'd need to mock `ui.instantiateImageCodec`.
      // This is hard. Let's focus on other state changes.

      await notifier.pickImage(ImageSource.gallery);

      expect(notifier.debugState.status, ImageScanStatus.imagePicked);
      expect(notifier.debugState.selectedImageFile, testFile);
      expect(notifier.debugState.errorMessage, isNull);
      // expect(notifier.debugState.imageSize, equals(ui.Size(100,100))); // This part is hard to unit test
    });

    test('handles user cancelling image picker', () async {
      fakeImagePickerPlatform.setCancelled(true);

      await notifier.pickImage(ImageSource.gallery);

      expect(notifier.debugState.status, ImageScanStatus.initial);
      expect(notifier.debugState.selectedImageFile, isNull);
    });

    test('handles exception during image picking', () async {
      final exception = Exception('Picker failed');
      fakeImagePickerPlatform.setNextException(exception);

      await notifier.pickImage(ImageSource.gallery);

      expect(notifier.debugState.status, ImageScanStatus.ocrError);
      expect(notifier.debugState.errorMessage, contains('Failed to pick image'));
      expect(notifier.debugState.selectedImageFile, isNull);
    });
  });

  group('processImage', () {
    final testFile = XFile('dummy_path/test_image.jpg', mimeType: 'image/jpeg');
    final testWords = [
      RecognizedWord(text: 'Hello', bounds: const ui.Rect.fromLTWH(0,0,10,10))
    ];

    setUp(() async {
      // Ensure there's a selected image before each processImage test
      fakeImagePickerPlatform.setNextXFile(testFile);
      await notifier.pickImage(ImageSource.gallery); // This sets up selectedImageFile and imageSize
      // Reset status to imagePicked if pickImage modified it further
      if (notifier.debugState.status != ImageScanStatus.imagePicked) {
         notifier.state = notifier.debugState.copyWith(status: ImageScanStatus.imagePicked);
      }
      // Clear any error message from picking
      notifier.state = notifier.debugState.copyWith(clearErrorMessage: true);
    });

    test('successfully processes image and updates state', () async {
      when(mockFunctionsService.callProcessImageForOcr(any, mimeType: anyNamed('mimeType')))
          .thenAnswer((_) async => testWords);

      await notifier.processImage();

      expect(notifier.debugState.status, ImageScanStatus.ocrSuccess);
      expect(notifier.debugState.recognizedWords, testWords);
      expect(notifier.debugState.errorMessage, isNull);
    });

    test('handles no image selected', () async {
      notifier.state = ImageScanState.initial(); // Reset to a state with no image

      await notifier.processImage();

      expect(notifier.debugState.status, ImageScanStatus.ocrError);
      expect(notifier.debugState.errorMessage, contains('No image selected'));
    });

    test('handles exception from FunctionsService', () async {
      final exception = Exception('OCR failed');
      when(mockFunctionsService.callProcessImageForOcr(any, mimeType: anyNamed('mimeType')))
          .thenThrow(exception);

      await notifier.processImage();

      expect(notifier.debugState.status, ImageScanStatus.ocrError);
      expect(notifier.debugState.errorMessage, contains('Failed to recognize text'));
      expect(notifier.debugState.recognizedWords, isEmpty);
    });
  });

  test('clearError clears the error message', () {
    // Setup initial state with an error
    notifier.state = notifier.debugState.copyWith(errorMessage: 'Some error', status: ImageScanStatus.ocrError);
    expect(notifier.debugState.errorMessage, 'Some error');

    notifier.clearError();

    expect(notifier.debugState.errorMessage, isNull);
    // Status should remain, only error message is cleared
    expect(notifier.debugState.status, ImageScanStatus.ocrError);
  });

  test('resetState resets to initial state', () {
    // Setup some non-initial state
    notifier.state = notifier.debugState.copyWith(
      selectedImageFile: XFile('dummy.jpg'),
      recognizedWords: [RecognizedWord(text: 'Test', bounds: ui.Rect.zero)],
      status: ImageScanStatus.ocrSuccess,
      errorMessage: 'Some error'
    );

    notifier.resetState();

    expect(notifier.debugState.status, ImageScanStatus.initial);
    expect(notifier.debugState.selectedImageFile, isNull);
    expect(notifier.debugState.recognizedWords, isEmpty);
    expect(notifier.debugState.errorMessage, isNull);
    expect(notifier.debugState.imageSize, isNull);
  });
}
