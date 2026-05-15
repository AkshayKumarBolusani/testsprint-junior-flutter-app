import 'package:flutter/material.dart';

/// Password self-service info for students (no backend email flow in MVP).
class ForgotPasswordInfoScreen extends StatelessWidget {
  const ForgotPasswordInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password help')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Student accounts cannot self-register or reset passwords in-app.\n\n'
          'Contact your administrator / support staff to reset your password.',
        ),
      ),
    );
  }
}
