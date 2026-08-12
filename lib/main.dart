import 'package:flutter/material.dart';
import 'features/auth/splash/splash_screen.dart';

void main() {
  runApp(const HealthcareCompanion());
}

class HealthcareCompanion extends StatelessWidget {
  const HealthcareCompanion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthcare Companion',
      home: const SplashScreen(),
    );
  }
}