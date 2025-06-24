// lib/screens/research_screen.dart
import 'package:flutter/material.dart';

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold is NOT const
      appBar: AppBar(
        // AppBar is NOT const
        title: const Text('KI Wortrecherche'), // Text IS const
      ),
      body: const Center(
        // Center IS const
        child: Text(
          // Inner const removed as Center is already const
          'KI Wortrecherche - Inhalt kommt hierher.',
        ),
      ),
    );
  }
}
