// lib/screens/image_scan_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/vocabulary_item.dart'; // For VocabularyItem and SourceType
import 'package:myapp/providers/auth_provider.dart'; // For getting userId
import 'package:myapp/providers/image_scan_provider.dart';
import 'package:myapp/services/firestore_service.dart'; // For saving vocabulary
// Note: RecognizedWord is now also in image_scan_provider.dart if we made it public, or keep from functions_service.dart
import 'package:myapp/services/functions_service.dart' show RecognizedWord;
import 'package:myapp/utils/app_localizations.dart'; // For localization


const String _scannedItemsTopicId = 'user_scanned_items'; // Topic ID for scanned items

class ImageScanScreen extends ConsumerWidget {
  const ImageScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageScanState = ref.watch(imageScanProvider);
    final imageScanNotifier = ref.read(imageScanProvider.notifier);

    // Listen for errors to show SnackBar
    ref.listen<ImageScanState>(imageScanProvider, (previous, next) {
      if (next.status == ImageScanStatus.ocrError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Optionally clear the error after showing it
        imageScanNotifier.clearError();
      }
    });

    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('imageScanScreenTitle', defaultValue: 'Text Recognition')), // Placeholder key
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: Text(localizations.translate('pickFromGalleryButton', defaultValue: 'Gallery')), // Placeholder key
                  onPressed: imageScanState.status == ImageScanStatus.pickingImage || imageScanState.status == ImageScanStatus.processingOcr
                      ? null // Disable if already processing
                      : () => imageScanNotifier.pickImage(ImageSource.gallery),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(localizations.translate('takePictureButton', defaultValue: 'Camera')), // Placeholder key
                  onPressed: imageScanState.status == ImageScanStatus.pickingImage || imageScanState.status == ImageScanStatus.processingOcr
                      ? null // Disable if already processing
                      : () => imageScanNotifier.pickImage(ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image Display Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                alignment: Alignment.center,
                child: _buildImageDisplay(context, imageScanState, imageScanNotifier),
              ),
            ),
            const SizedBox(height: 20),

            // Process Button
            if (imageScanState.selectedImageFile != null && imageScanState.status == ImageScanStatus.imagePicked)
              ElevatedButton.icon(
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(localizations.translate('processImageButton', defaultValue: 'Recognize Text')), // Placeholder key
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: imageScanState.status == ImageScanStatus.processingOcr
                    ? null
                    : () => imageScanNotifier.processImage(),
              ),

            // Reset Button
            if (imageScanState.selectedImageFile != null || imageScanState.recognizedWords.isNotEmpty)
              TextButton(
                child: Text(localizations.translate('resetButton', defaultValue: 'Reset')),
                onPressed: () => imageScanNotifier.resetState(),
              ),

            // Loading Indicator (overlay might be better, but simple for now)
            if (imageScanState.status == ImageScanStatus.pickingImage || imageScanState.status == ImageScanStatus.processingOcr)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay(BuildContext context, ImageScanState imageScanState, ImageScanNotifier notifier) {
    final localizations = AppLocalizations.of(context)!;

    if (imageScanState.selectedImageFile != null) {
      // If image is selected, display it with word overlays
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // constraints.maxWidth and constraints.maxHeight are the available space for the image
          final double availableWidth = constraints.maxWidth;
          final double availableHeight = constraints.maxHeight;

          if (imageScanState.imageSize == null || imageScanState.imageSize!.isEmpty) {
            // This might happen briefly before imageSize is loaded by the provider
            return const Center(child: CircularProgressIndicator());
          }

          // Calculate the scale factor to fit the image within the available space, maintaining aspect ratio
          final double imgAspect = imageScanState.imageSize!.width / imageScanState.imageSize!.height;
          final double containerAspect = availableWidth / availableHeight;

          double displayWidth;
          double displayHeight;

          if (imgAspect > containerAspect) { // Image is wider than container
            displayWidth = availableWidth;
            displayHeight = displayWidth / imgAspect;
          } else { // Image is taller than or same aspect as container
            displayHeight = availableHeight;
            displayWidth = displayHeight * imgAspect;
          }

          // Calculate scaling factors for bounding boxes
          final double scaleX = displayWidth / imageScanState.imageSize!.width;
          final double scaleY = displayHeight / imageScanState.imageSize!.height;

          return Stack(
            alignment: Alignment.center, // Center the image within the Stack
            children: <Widget>[
              // Display the image
              Image.file(
                File(imageScanState.selectedImageFile!.path),
                width: displayWidth,
                height: displayHeight,
                fit: BoxFit.contain, // Ensure the whole image is visible
              ),
              // Overlay recognized words
              if (imageScanState.status == ImageScanStatus.ocrSuccess && imageScanState.recognizedWords.isNotEmpty)
                ...imageScanState.recognizedWords.map((word) {
                  // Scale and position the word's bounding box
                  final Rect originalBox = word.bounds;
                  final double left = originalBox.left * scaleX;
                  final double top = originalBox.top * scaleY;
                  final double width = originalBox.width * scaleX;
                  final double height = originalBox.height * scaleY;

                  return Positioned(
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                    child: Material( // Material for InkWell splash
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async { // Make async for saving
                          final String currentWordText = word.text;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(localizations.translate('wordTappedMessage', defaultValue: 'Tapped: ') + currentWordText)),
                          );

                          // Get current user
                          final user = ref.read(authStateChangesProvider).value;
                          if (user == null || user.uid.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.translate('mustBeLoggedInToSaveError', defaultValue: 'You must be logged in to save words.')),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                            return;
                          }
                          final String userId = user.uid;

                          // Create VocabularyItem
                          final String newItemId = 'scanned-${currentWordText.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}-${DateTime.now().millisecondsSinceEpoch}';
                          final VocabularyItem newItem = VocabularyItem(
                            id: newItemId,
                            word: currentWordText,
                            definitions: {'de': localizations.translate('scannedFromImageDefaultDef', defaultValue: 'Scanned from image')}, // Default definition
                            synonyms: [],
                            collocations: [],
                            exampleSentences: {},
                            level: 'C1', // Default level
                            sourceType: SourceType.scanned_text,
                            topicId: _scannedItemsTopicId,
                            grammarHint: null,
                            contextualText: null,
                          );

                          try {
                            await ref.read(firestoreServiceProvider).saveVocabularyItem(userId, newItem);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.translate('wordSavedSuccessMessage', defaultValue: '"${newItem.word}" saved!')),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            print('Error saving vocabulary item: $e'); // Debug print
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.translate('wordSaveFailedError', defaultValue: 'Failed to save word: $e')),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        },
                        splashColor: Colors.lightBlue.withOpacity(0.3),
                        hoverColor: Colors.lightBlue.withOpacity(0.1),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent.withOpacity(0.7), width: 1.5),
                            color: Colors.yellow.withOpacity(0.2),
                          ),
                          alignment: Alignment.center,
                          // Optional: Display text within the box if it's large enough
                          // child: FittedBox(
                          //   child: Text(
                          //     word.text,
 Daunting_style: const TextStyle(color: Colors.black, fontSize: 8),
                          //   ),
                          // ),
                        ),
                      ),
                    ),
                  );
                }).toList(),

              // Show a simpler loading indicator when processing OCR right on top of the image
              if (imageScanState.status == ImageScanStatus.processingOcr)
                Container(
                  width: displayWidth,
                  height: displayHeight,
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator( backgroundColor: Colors.white,)),
                ),
            ],
          );
        },
      );
    } else if (imageScanState.status == ImageScanStatus.pickingImage) {
      return const Center(child: CircularProgressIndicator());
    } else {
      // Placeholder when no image is selected
      return Center(
        child: Text(
          localizations.translate('selectImagePrompt', defaultValue: 'Select an image or take a photo to start.'), // Placeholder key
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
  }
}
