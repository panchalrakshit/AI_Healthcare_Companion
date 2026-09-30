import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/DoctorDashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'features/auth/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HealthcareCompanion());
}

class HealthcareCompanion extends StatelessWidget {
  const HealthcareCompanion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthcare Companion',
      home: const SplashScreen()
      //const DoctorDashboard(),
    );
  }
}