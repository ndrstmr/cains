// lib/screens/wordgrid_screen.dart
import 'package:flutter/material.dart';

class WordGridScreen extends StatelessWidget {
  const WordGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold is NOT const
      appBar: AppBar(
        // AppBar is NOT const
        title: const Text('Wortgitter Spiel'), // Text IS const
      ),
      body: const Center(
        // Center IS const
        child: Text(
          // Inner const removed
          'Wortgitter Spiel - Inhalt kommt hierher.',
        ),
      ),
    );
  }
}
