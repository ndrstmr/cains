// lib/screens/scan_screen.dart
import 'package:flutter/material.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold is NOT const
      appBar: AppBar(
        // AppBar is NOT const
        title: const Text('Text Scannen'), // Text IS const
      ),
      body: const Center(
        // Center IS const
        child: Text(
          // Inner const removed
          'Text Scannen (Kamera) - Inhalt kommt hierher.',
        ),
      ),
    );
  }
}
