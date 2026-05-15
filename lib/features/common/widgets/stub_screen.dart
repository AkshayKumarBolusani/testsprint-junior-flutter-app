import 'package:flutter/material.dart';

/// Lightweight placeholder used by screens that are intentionally MVP stubs.
class StubScreen extends StatelessWidget {
  const StubScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title\n\nThis screen is scaffolded for navigation and can be extended with full CRUD flows.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
