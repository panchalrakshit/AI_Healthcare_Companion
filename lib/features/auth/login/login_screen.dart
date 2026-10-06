import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/AdminDashboard.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/DoctorDashboard.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/Patient_dashboard.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/login/signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  bool _obscurePassword = true;

  bool _isLoading = false;

  String _selectedRole = 'Patient';

  final List<String> _roles = [
    'Patient',
    'Doctor',
    'Admin',
  ];

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

  Future<void> _loginUser() async {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFFF7FF),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),

          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 520,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // =====================================================
                // LOGO
                // =====================================================

                Center(
                  child: Container(
                    height: 56,
                    width: 56,

                    decoration: BoxDecoration(
                      color:
                      const Color(0xFF222222),

                      borderRadius:
                      BorderRadius.circular(16),
                    ),

                    child: Image.asset("lib/logo/HealthCompanionLogo1.png",height: 90,width: 90)
                  ),
                ),

                const SizedBox(
                  height: 45,
                ),

                // =====================================================
                // HEADING
                // =====================================================

                const Center(
                  child: Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF202020),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Center(
                  child: Text(
                    "Login to continue to "
                        "HealthCompanion",

                    textAlign:
                    TextAlign.center,

                    style: TextStyle(
                      fontSize: 16,
                      color:
                      Color(0xFF999999),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 35,
                ),

                // =====================================================
                // LOGIN AS
                // =====================================================

                const Text(
                  "Login As",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF202020),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                // =====================================================
                // ROLE DROPDOWN
                // =====================================================

                DropdownButtonFormField<String>(
                  value:
                  _selectedRole,

                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color:
                    Color(0xFF7352B5),
                  ),

                  dropdownColor:
                  const Color(0xFFFFF7FF),

                  decoration:
                  InputDecoration(
                    prefixIcon: Icon(
                      _selectedRole == 'Doctor'
                          ? Icons.medical_services_outlined
                          : _selectedRole == 'Admin'
                          ? Icons.admin_panel_settings_outlined
                          : Icons.person_outline,
                    ),

                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(0xFF999999),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),

                  items:
                  _roles.map(
                        (String role) {
                      return DropdownMenuItem<
                          String>(
                        value: role,

                        child: Row(
                          children: [

                            Icon(
                              role == 'Doctor'
                                  ? Icons.medical_services_outlined
                                  : role == 'Admin'
                                  ? Icons.admin_panel_settings_outlined
                                  : Icons.person_outline,

                              size: 20,

                              color:
                              const Color(
                                0xFF7352B5,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Text(
                              role,

                              style:
                              const TextStyle(
                                fontSize: 16,
                                color:
                                Color(
                                  0xFF202020,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(),

                  onChanged:
                  _isLoading
                      ? null
                      : (String?
                  newValue) {
                    if (newValue !=
                        null) {
                      setState(() {
                        _selectedRole =
                            newValue;
                      });
                    }
                  },
                ),

                const SizedBox(
                  height: 25,
                ),

                // =====================================================
                // EMAIL
                // =====================================================

                const Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF202020),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                TextField(
                  controller:
                  _emailController,

                  enabled:
                  !_isLoading,

                  keyboardType:
                  TextInputType
                      .emailAddress,

                  decoration:
                  InputDecoration(
                    hintText:
                    "Enter your email",

                    prefixIcon:
                    const Icon(
                      Icons.email_outlined,
                    ),

                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(0xFF999999),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // =====================================================
                // PASSWORD
                // =====================================================

                const Text(
                  "Password",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF202020),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                TextField(
                  controller:
                  _passwordController,

                  enabled:
                  !_isLoading,

                  obscureText:
                  _obscurePassword,

                  decoration:
                  InputDecoration(
                    hintText:
                    "Enter your password",

                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon:
                    IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons
                            .visibility_off_outlined
                            : Icons
                            .visibility_outlined,
                      ),

                      onPressed:
                      _isLoading
                          ? null
                          : () {
                        setState(() {
                          _obscurePassword =
                          !_obscurePassword;
                        });
                      },
                    ),

                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(0xFF999999),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // =====================================================
                // FORGOT PASSWORD
                // =====================================================

                Align(
                  alignment:
                  Alignment.centerRight,

                  child: TextButton(
                    onPressed:
                    _isLoading
                        ? null
                        : () {
                      // Password reset
                      // will be added later.
                    },

                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color:
                        Color(0xFF7352B5),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // =====================================================
                // LOGIN BUTTON
                // =====================================================

                SizedBox(
                  width:
                  double.infinity,

                  height: 58,

                  child:
                  ElevatedButton(
                    onPressed:
                    _isLoading
                        ? null
                        : _loginUser,

                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      const Color(
                        0xFFF7F1FA,
                      ),

                      foregroundColor:
                      const Color(
                        0xFF7352B5,
                      ),

                      disabledBackgroundColor:
                      const Color(
                        0xFFF7F1FA,
                      ),

                      disabledForegroundColor:
                      const Color(
                        0xFF7352B5,
                      ),

                      elevation: 0,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          30,
                        ),

                        side:
                        const BorderSide(
                          color:
                          Color(
                            0xFFE2D9E7,
                          ),
                        ),
                      ),
                    ),

                    child:
                    _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,

                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2.5,

                        color:
                        Color(
                          0xFF7352B5,
                        ),
                      ),
                    )
                        : const Text(
                      "Login",

                      style:
                      TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight
                            .w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // =====================================================
                // SIGN UP
                // =====================================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,

                  children: [

                    const Text(
                      "Don't have an account? ",

                      style:
                      TextStyle(
                        fontSize: 15,
                        color:
                        Color(0xFF333333),
                      ),
                    ),

                    TextButton(
                      onPressed:
                      _isLoading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                            const SignupScreen(),
                          ),
                        );
                      },

                      child: const Text(
                        "Sign Up",

                        style:
                        TextStyle(
                          fontSize: 15,
                          color:
                          Color(
                            0xFF7352B5,
                          ),
                          fontWeight:
                          FontWeight
                              .w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}