import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/AdminDashboard.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/DoctorDashboard.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/Patient_dashboard.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/login/signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  // =========================================================
  // VARIABLES
  // =========================================================

  bool _isLoading = false;

  String _selectedRole = 'Patient';


  // =========================================================
  // FIREBASE INSTANCES
  // =========================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOGIN FUNCTION
  // =========================================================

  Future<void> _resetPassword() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showMessage('Enter your email above, then select Forgot Password.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) _showMessage('If an account exists for this email, a password reset link has been sent.');
    } on FirebaseAuthException catch (e) {
      if (mounted) _showMessage(e.code == 'too-many-requests'
        ? 'Too many requests. Please try again later.'
        : 'Could not send the reset link. Check the email and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginUser() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    // ---------------------------------------------------------
    // GET VALUES
    // ---------------------------------------------------------

    final String email =
    _emailController.text.trim();

    // Do NOT trim the password.
    // A password can technically contain spaces.
    final String password =
        _passwordController.text;

    // ---------------------------------------------------------
    // BASIC VALIDATION
    // ---------------------------------------------------------

    if (email.isEmpty) {
      _showMessage(
        "Please enter your email.",
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        "Please enter your password.",
      );
      return;
    }

    if (!email.contains("@") ||
        !email.contains(".")) {
      _showMessage(
        "Please enter a valid email address.",
      );
      return;
    }

    // ---------------------------------------------------------
    // START LOADING
    // ---------------------------------------------------------

    setState(() {
      _isLoading = true;
    });

    try {
      // =======================================================
      // STEP 1
      // FIREBASE AUTHENTICATION
      // =======================================================

      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // =======================================================
      // STEP 2
      // GET LOGGED-IN USER
      // =======================================================

      final User? user =
          userCredential.user;

      if (user == null) {
        throw Exception(
          "Unable to retrieve logged-in user.",
        );
      }

      // =======================================================
      // STEP 3
      // GET UID
      // =======================================================

      final String uid = user.uid;

      debugPrint(
        "Logged in UID: $uid",
      );

      // =======================================================
      // STEP 4
      // GET USER DOCUMENT FROM FIRESTORE
      //
      // users
      //   └── UID
      //
      // =======================================================

      final DocumentSnapshot<Map<String, dynamic>>
      userDocument =
      await _firestore
          .collection('users')
          .doc(uid)
          .get();

      // =======================================================
      // STEP 5
      // CHECK PROFILE EXISTS
      // =======================================================

      if (!userDocument.exists) {
        await _auth.signOut();

        if (!mounted) return;

        _showMessage(
          "User profile not found. Please contact support.",
        );

        return;
      }

      // =======================================================
      // STEP 6
      // READ USER DATA
      // =======================================================

      final Map<String, dynamic>? userData =
      userDocument.data();

      if (userData == null) {
        await _auth.signOut();

        if (!mounted) return;

        _showMessage(
          "Unable to read your user profile.",
        );

        return;
      }

      // =======================================================
      // STEP 7
      // GET ROLE
      // =======================================================

      final String role =
      (userData['role'] ?? '')
          .toString()
          .toLowerCase();

      // =======================================================
      // STEP 8
      // GET STATUS
      // =======================================================

      final String status =
      (userData['status'] ?? '')
          .toString()
          .toLowerCase();

      debugPrint(
        "Firestore Role: $role",
      );

      debugPrint(
        "Firestore Status: $status",
      );

      // =======================================================
      // STEP 9
      // CHECK ACCOUNT STATUS
      // =======================================================

      if (status != "active") {
        await _auth.signOut();

        if (!mounted) return;

        _showMessage(
          "Your account is currently $status.",
        );

        return;
      }

      // =======================================================
      // STEP 10
      // CHECK SELECTED ROLE
      //
      // Firestore is the source of truth.
      //
      // =======================================================

      final String selectedRole =
      _selectedRole.toLowerCase();

      if (role != selectedRole) {
        await _auth.signOut();

        if (!mounted) return;

        _showMessage(
          "This account is registered as "
              "${role.toUpperCase()}, not "
              "${selectedRole.toUpperCase()}.",
        );

        return;
      }

      // =======================================================
      // STEP 11
      // LOGIN SUCCESSFUL
      // =======================================================

      if (!mounted) return;

      TextInput.finishAutofillContext(shouldSave: true);
      _showSuccessMessage();

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      // =======================================================
      // STEP 12
      // NAVIGATE USING FIRESTORE ROLE
      // =======================================================

      if (role == "patient") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const PatientDashboard(),
          ),
        );
      }

      else if (role == "doctor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const DoctorDashboard(),
          ),
        );
      }

      else if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const AdminDashboard(),
          ),
        );
      }

      else {
        await _auth.signOut();

        if (!mounted) return;

        _showMessage(
          "Invalid account role. "
              "Please contact support.",
        );
      }
    }

    // =========================================================
    // FIREBASE AUTH ERRORS
    // =========================================================

    on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message =
          "The email address is not valid.";
          break;

        case 'user-not-found':
          message =
          "No account found with this email.";
          break;

        case 'wrong-password':
          message =
          "Incorrect password.";
          break;

        case 'invalid-credential':
          message =
          "Invalid email or password.";
          break;

        case 'user-disabled':
          message =
          "This account has been disabled.";
          break;

        case 'too-many-requests':
          message =
          "Too many login attempts. "
              "Please try again later.";
          break;

        case 'network-request-failed':
          message =
          "Network error. "
              "Please check your internet connection.";
          break;

        default:
          message =
              e.message ??
                  "Login failed. Please try again.";
      }

      if (mounted) {
        _showMessage(message);
      }
    }

    // =========================================================
    // OTHER ERRORS
    // =========================================================

    catch (e) {
      debugPrint(
        "Login error: $e",
      );

      if (mounted) {
        _showMessage(
          "Unable to complete login. "
              "Please try again.",
        );
      }
    }

    // =========================================================
    // STOP LOADING
    // =========================================================

    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // SUCCESS MESSAGE
  // =========================================================

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                "Login successful!",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        backgroundColor:
        Color(0xFF168A62),

        duration:
        Duration(milliseconds: 800),
      ),
    );
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),

        duration:
        const Duration(seconds: 3),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) => LoginView(
    email: _emailController, password: _passwordController, role: _selectedRole, busy: _isLoading,
    onRole: (role) => setState(() => _selectedRole = role), onLogin: _loginUser, onReset: _resetPassword,
    onSignup: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
  );
}
