import 'package:ai_healthcompanion_using_flutter/features/auth/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ============================================================
  // PASSWORD VISIBILITY
  // ============================================================

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ============================================================
  // LOADING STATE
  // ============================================================

  bool _isLoading = false;

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // CREATE PATIENT ACCOUNT
  // ============================================================

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    // ----------------------------------------------------------
    // GET VALUES
    // ----------------------------------------------------------

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword =
        _confirmPasswordController.text;

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty) {
      _showMessage("Please enter your full name");
      return;
    }

    if (name.length < 3) {
      _showMessage("Please enter a valid full name");
      return;
    }

    if (email.isEmpty) {
      _showMessage("Please enter your email address");
      return;
    }

    if (!email.contains("@") || !email.contains(".")) {
      _showMessage("Please enter a valid email address");
      return;
    }

    if (phone.isEmpty) {
      _showMessage("Please enter your phone number");
      return;
    }

    if (phone.length < 10) {
      _showMessage("Please enter a valid phone number");
      return;
    }

    if (password.isEmpty) {
      _showMessage("Please create a password");
      return;
    }

    if (password.length < 6) {
      _showMessage(
        "Password must contain at least 6 characters",
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage("Please confirm your password");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match");
      return;
    }

    // ----------------------------------------------------------
    // START LOADING
    // ----------------------------------------------------------

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================
      // STEP 1: CREATE FIREBASE AUTH ACCOUNT
      // ========================================================

      UserCredential userCredential =
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ========================================================
      // STEP 2: GET CREATED USER
      // ========================================================

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception("User creation failed");
      }

      // ========================================================
      // STEP 3: SAVE DISPLAY NAME IN FIREBASE AUTH
      // ========================================================

      await user.updateDisplayName(name);

      // ========================================================
      // STEP 4: CREATE USER PROFILE IN FIRESTORE
      // ========================================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': phone,

        // Every account created through this page
        // is a patient account.
        'role': 'patient',

        // New patient accounts are active.
        'status': 'active',

        'createdAt': FieldValue.serverTimestamp(),
      });

      // ========================================================
      // STEP 5: CREATE EMPTY HEALTH PROFILE
      // ========================================================
      //
      // IMPORTANT:
      //
      // We DO NOT add dummy medical information here.
      //
      // Every health field starts as null because the patient
      // has not provided any health information yet.
      //
      // Document structure:
      //
      // healthProfiles/{user.uid}
      //
      // ========================================================

      await FirebaseFirestore.instance
          .collection('healthProfiles')
          .doc(user.uid)
          .set({
        'uid': user.uid,

        // ------------------------------------------------------
        // BASIC HEALTH INFORMATION
        // ------------------------------------------------------

        'bloodPressure': null,
        'bloodSugar': null,
        'heartRate': null,
        'spo2': null,
        'temperature': null,
        'weight': null,
        'height': null,
        'bmi': null,

        // ------------------------------------------------------
        // ADDITIONAL HEALTH INFORMATION
        // ------------------------------------------------------

        'bloodGroup': null,
        'gender': null,
        'dateOfBirth': null,

        // ------------------------------------------------------
        // MEDICAL INFORMATION
        // ------------------------------------------------------

        'allergies': null,
        'existingConditions': null,
        'currentMedications': null,

        // ------------------------------------------------------
        // CHECKUP INFORMATION
        // ------------------------------------------------------

        'lastCheckup': null,

        // ------------------------------------------------------
        // PROFILE STATUS
        // ------------------------------------------------------

        'profileCompleted': false,

        // ------------------------------------------------------
        // TIMESTAMP
        // ------------------------------------------------------

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ========================================================
      // STEP 6: SIGN OUT
      // ========================================================
      //
      // Firebase automatically signs the user in immediately
      // after account creation.
      //
      // Current application flow:
      //
      // Signup → Login → Dashboard
      //
      // Therefore, sign out after successful signup.
      //
      // ========================================================

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // ========================================================
      // STEP 7: SUCCESS MESSAGE
      // ========================================================

      _showSuccessMessage();

      // ========================================================
      // STEP 8: WAIT BEFORE NAVIGATION
      // ========================================================

      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (!mounted) return;

      // ========================================================
      // STEP 9: GO TO LOGIN
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERRORS
    // ==========================================================

    on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
          "An account already exists with this email.";
          break;

        case 'invalid-email':
          message =
          "Please enter a valid email address.";
          break;

        case 'weak-password':
          message =
          "The password is too weak.";
          break;

        case 'operation-not-allowed':
          message =
          "Email/Password authentication is not enabled.";
          break;

        case 'network-request-failed':
          message =
          "Network error. Please check your internet connection.";
          break;

        default:
          message =
              e.message ?? "Something went wrong.";
      }

      if (mounted) {
        _showMessage(message);
      }
    }

    // ==========================================================
    // GENERAL ERROR
    // ==========================================================

    catch (e) {
      debugPrint("Signup error: $e");

      if (mounted) {
        _showMessage(
          "Something went wrong. Please try again.",
        );
      }
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

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
                "Patient account created successfully!",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF168A62),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // ERROR / INFORMATION MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 30,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 560,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  // ==================================================
                  // HEADER
                  // ==================================================

                  Center(
                    child: Column(
                      children: [

                        Container(
                          height: 72,
                          width: 72,

                          decoration: BoxDecoration(
                            gradient:
                            const LinearGradient(
                              colors: [
                                Color(0xFF7352B5),
                                Color(0xFF5B3BA5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),

                            borderRadius:
                            BorderRadius.circular(22),

                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7352B5,
                                ).withOpacity(0.20),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),

                          child: const Icon(
                            Icons.health_and_safety_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          "Create Your Account",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF202033),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Your health journey starts here",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF777384),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // PATIENT INFORMATION CARD
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                      BorderRadius.circular(18),

                      border: Border.all(
                        color: const Color(0xFFE4E0EF),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.035),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            Container(
                              height: 42,
                              width: 42,

                              decoration: BoxDecoration(
                                color:
                                const Color(0xFFF0EBFF),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),

                              child: const Icon(
                                Icons.person_outline_rounded,
                                color:
                                Color(0xFF7352B5),
                                size: 23,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Patient Information",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(0xFF252332),
                                  ),
                                ),

                                SizedBox(height: 3),

                                Text(
                                  "Tell us a little about yourself",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                    Color(0xFF888492),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // FULL NAME

                        _fieldLabel(
                          "Full Name",
                          Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 9),

                        _buildTextField(
                          controller: _nameController,
                          hintText:
                          "Enter your full name",
                          icon:
                          Icons.person_outline_rounded,
                          keyboardType:
                          TextInputType.name,
                        ),

                        const SizedBox(height: 20),

                        // EMAIL

                        _fieldLabel(
                          "Email Address",
                          Icons.email_outlined,
                        ),

                        const SizedBox(height: 9),

                        _buildTextField(
                          controller: _emailController,
                          hintText:
                          "Enter your email address",
                          icon: Icons.email_outlined,
                          keyboardType:
                          TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        // PHONE

                        _fieldLabel(
                          "Phone Number",
                          Icons.phone_outlined,
                        ),

                        const SizedBox(height: 9),

                        _buildTextField(
                          controller: _phoneController,
                          hintText:
                          "Enter your phone number",
                          icon: Icons.phone_outlined,
                          keyboardType:
                          TextInputType.phone,
                        ),

                        const SizedBox(height: 20),

                        // PASSWORD

                        _fieldLabel(
                          "Password",
                          Icons.lock_outline_rounded,
                        ),

                        const SizedBox(height: 9),

                        _buildPasswordField(
                          controller: _passwordController,
                          hintText:
                          "Create a secure password",
                          obscureText: _obscurePassword,
                          onVisibilityPressed: () {
                            setState(() {
                              _obscurePassword =
                              !_obscurePassword;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // CONFIRM PASSWORD

                        _fieldLabel(
                          "Confirm Password",
                          Icons.lock_outline_rounded,
                        ),

                        const SizedBox(height: 9),

                        _buildPasswordField(
                          controller:
                          _confirmPasswordController,
                          hintText:
                          "Re-enter your password",
                          obscureText:
                          _obscureConfirmPassword,
                          onVisibilityPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                            });
                          },
                        ),

                        const SizedBox(height: 25),

                        // SECURITY INFORMATION

                        Container(
                          padding:
                          const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFF5F2FF),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),

                          child: const Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              Icon(
                                Icons
                                    .verified_user_outlined,
                                size: 19,
                                color:
                                Color(0xFF7352B5),
                              ),

                              SizedBox(width: 9),

                              Expanded(
                                child: Text(
                                  "Your account information is securely "
                                      "protected. Your password is managed "
                                      "securely by Firebase Authentication.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.5,
                                    color:
                                    Color(0xFF686477),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // CREATE ACCOUNT BUTTON

                        SizedBox(
                          width: double.infinity,
                          height: 56,

                          child: ElevatedButton(
                            onPressed:
                            _isLoading
                                ? null
                                : _createAccount,

                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF7352B5),

                              foregroundColor:
                              Colors.white,

                              disabledBackgroundColor:
                              const Color(0xFFC8BFE0),

                              elevation: 0,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                            ),

                            child: _isLoading
                                ? const SizedBox(
                              height: 25,
                              width: 25,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color:
                                Colors.white,
                              ),
                            )
                                : const Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                              children: [

                                Icon(
                                  Icons
                                      .person_add_alt_1_rounded,
                                  size: 21,
                                ),

                                SizedBox(width: 9),

                                Text(
                                  "Create Patient Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // LOGIN

                  Center(
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [

                        const Text(
                          "Already have an account?",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666273),
                          ),
                        ),

                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const LoginScreen(),
                              ),
                            );
                          },

                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 14,
                              color:
                              Color(0xFF7352B5),
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // FOOTER

                  const Center(
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [

                        Icon(
                          Icons
                              .health_and_safety_outlined,
                          size: 15,
                          color: Color(0xFF9A95A6),
                        ),

                        SizedBox(width: 5),

                        Text(
                          "Smart Hospital • Healthcare Companion",
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9A95A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIELD LABEL
  // ============================================================

  Widget _fieldLabel(
      String label,
      IconData icon,
      ) {
    return Row(
      children: [

        Icon(
          icon,
          size: 17,
          color: const Color(0xFF7352B5),
        ),

        const SizedBox(width: 7),

        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF292637),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NORMAL TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,

      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF292637),
      ),

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFFA09BAA),
        ),

        prefixIcon: Icon(
          icon,
          color: const Color(0xFF8B8499),
          size: 21,
        ),

        filled: true,
        fillColor: const Color(0xFFFAF9FC),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE3DFEA),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF7352B5),
            width: 1.7,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onVisibilityPressed,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,

      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF292637),
      ),

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFFA09BAA),
        ),

        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF8B8499),
          size: 21,
        ),

        suffixIcon: IconButton(
          onPressed: onVisibilityPressed,

          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF8B8499),
            size: 21,
          ),
        ),

        filled: true,
        fillColor: const Color(0xFFFAF9FC),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE3DFEA),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF7352B5),
            width: 1.7,
          ),
        ),
      ),
    );
  }
}