// lib/providers/image_scan_provider.dart
import 'dart:convert';
import 'dart:io'; // Required for File, though XFile is preferred from image_picker
import 'dart:ui' as ui; // For ui.Image, ui.Codec, Size

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/services/functions_service.dart'; // Assuming this is the correct path
import 'package:flutter/foundation.dart'; // for kDebugMode

// Enum for managing the status of the image scanning process
enum ImageScanStatus {
  initial, // No image selected, ready to pick
  pickingImage, // In the process of selecting an image from gallery/camera
  imagePicked, // Image selected, ready for OCR or re-selection
  processingOcr, // OCR is in progress
  ocrSuccess, // OCR completed successfully, words are available
  ocrError, // An error occurred during picking or OCR
}

// State class for the ImageScanNotifier
@immutable
class ImageScanState {
  final XFile? selectedImageFile; // The image file picked by the user
  final List<RecognizedWord> recognizedWords;
  final String? errorMessage;
  final ImageScanStatus status;
  final ui.Size? imageSize; // Actual dimensions of the loaded image

  const ImageScanState({
    this.selectedImageFile,
    this.recognizedWords = const [],
    this.errorMessage,
    this.status = ImageScanStatus.initial,
    this.imageSize,
  });

  // Initial state factory
  factory ImageScanState.initial() {
    return const ImageScanState();
  }

  // CopyWith method for immutability
  ImageScanState copyWith({
    XFile? selectedImageFile,
    List<RecognizedWord>? recognizedWords,
    String? errorMessage,
    ImageScanStatus? status,
    ui.Size? imageSize,
    bool clearSelectedImage = false, // Special flag to nullify selectedImageFile
    bool clearErrorMessage = false, // Special flag to nullify errorMessage
    bool clearImageSize = false, // Special flag to nullify imageSize
  }) {
    return ImageScanState(
      selectedImageFile: clearSelectedImage ? null : selectedImageFile ?? this.selectedImageFile,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      imageSize: clearImageSize ? null : imageSize ?? this.imageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageScanState &&
        other.selectedImageFile == selectedImageFile &&
        listEquals(other.recognizedWords, recognizedWords) &&
        other.errorMessage == errorMessage &&
        other.status == status &&
        other.imageSize == imageSize;
  }

  @override
  int get hashCode {
    return selectedImageFile.hashCode ^
        recognizedWords.hashCode ^
        errorMessage.hashCode ^
        status.hashCode ^
        imageSize.hashCode;
  }
}

// StateNotifier for image scanning logic
class ImageScanNotifier extends StateNotifier<ImageScanState> {
  final FunctionsService _functionsService;
  final ImagePicker _imagePicker;

  ImageScanNotifier(this._functionsService, this._imagePicker)
      : super(ImageScanState.initial());

  // Method to pick an image from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    state = state.copyWith(status: ImageScanStatus.pickingImage, clearErrorMessage: true, recognizedWords: []);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        // Get image dimensions
        final bytes = await pickedFile.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image image = frameInfo.image;

        state = state.copyWith(
          selectedImageFile: pickedFile,
          imageSize: ui.Size(image.width.toDouble(), image.height.toDouble()),
          status: ImageScanStatus.imagePicked,
          recognizedWords: [], // Clear previous words
        );
        if (kDebugMode) {
          print('Image picked: ${pickedFile.path}, size: ${state.imageSize}');
        }
      } else {
        // User cancelled picker
        state = state.copyWith(status: ImageScanStatus.initial); // Or previous status if applicable
         if (kDebugMode) {
          print('Image picking cancelled by user.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      state = state.copyWith(
          errorMessage: 'Failed to pick image: ${e.toString()}',
          status: ImageScanStatus.ocrError // Generic error state for simplicity
          );
    }
  }

  // Method to process the selected image for OCR
  Future<void> processImage() async {
    if (state.selectedImageFile == null) {
      state = state.copyWith(
          errorMessage: 'No image selected to process.',
          status: ImageScanStatus.ocrError);
      return;
    }
    state = state.copyWith(status: ImageScanStatus.processingOcr, clearErrorMessage: true, recognizedWords: []);

    try {
      final bytes = await state.selectedImageFile!.readAsBytes();
      final String base64Image = base64Encode(bytes);
      final String? mimeType = state.selectedImageFile!.mimeType;

      if (kDebugMode) {
        print('Processing image for OCR. MimeType: $mimeType, Base64 length: ${base64Image.length}');
      }

      final List<RecognizedWord> words = await _functionsService
          .callProcessImageForOcr(base64Image, mimeType: mimeType);

      state = state.copyWith(
        recognizedWords: words,
        status: ImageScanStatus.ocrSuccess,
      );
      if (kDebugMode) {
        print('OCR successful. Found ${words.length} words.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing image for OCR: $e');
      }
      state = state.copyWith(
        errorMessage: 'Failed to recognize text: ${e.toString()}',
        status: ImageScanStatus.ocrError,
        recognizedWords: [], // Clear any partial results
      );
    }
  }

  // Method to clear the current error message
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearErrorMessage: true);
    }
  }

  // Method to reset the state to initial, clearing selected image and results
  void resetState() {
    state = ImageScanState.initial();
     if (kDebugMode) {
      print('ImageScanNotifier state reset.');
    }
  }
}

// Provider definition
// We need to make sure functionsServiceProvider is available and correctly defined.
// Let's assume it will be correctly set up.
// Also, ImagePicker can be provided or instantiated directly. For simplicity, instantiating here.
final imageScanProvider =
    StateNotifierProvider<ImageScanNotifier, ImageScanState>((ref) {
  final functionsService = ref.watch(functionsServiceProvider); // Ensure this provider exists
  return ImageScanNotifier(functionsService, ImagePicker());
});

// It seems 'functionsServiceProvider' from 'functions_service.dart' was commented out.
// It should be uncommented and properly defined for the above to work.
// Example of what might be in functions_service.dart:
// final functionsServiceProvider = Provider<FunctionsService>((ref) {
//   return FunctionsService(FirebaseAuth.instance); // Assuming FirebaseAuth is available via another provider or globally
// });
