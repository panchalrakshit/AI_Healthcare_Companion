import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedRole = 'Patient';

  final List<String> _roles = [
    'Patient',
    'Doctor',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),

          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // =========================================================
                // LOGO
                // =========================================================

                Container(
                  height: 56,
                  width: 56,

                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 40),

                // =========================================================
                // HEADING
                // =========================================================

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Create your Healthcare Companion account",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF999999),
                  ),
                ),

                const SizedBox(height: 32),

                // =========================================================
                // ACCOUNT TYPE
                // =========================================================

                const Text(
                  "Account Type",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202020),
                  ),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: _selectedRole,

                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF7352B5),
                  ),

                  dropdownColor: const Color(0xFFFFF7FF),

                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      _selectedRole == 'Doctor'
                          ? Icons.medical_services_outlined
                          : Icons.person_outline,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF999999),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),

                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,

                      child: Row(
                        children: [
                          Icon(
                            role == 'Doctor'
                                ? Icons.medical_services_outlined
                                : Icons.person_outline,
                            size: 20,
                            color: const Color(0xFF7352B5),
                          ),

                          const SizedBox(width: 12),

                          Text(
                            role,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF202020),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 25),

                // =========================================================
                // FULL NAME
                // =========================================================

                const Text(
                  "Full Name",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202020),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  keyboardType: TextInputType.name,

                  decoration: InputDecoration(
                    hintText: "Enter your full name",

                    prefixIcon: const Icon(
                      Icons.person_outline,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF999999),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // =========================================================
                // EMAIL
                // =========================================================

                const Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202020),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  keyboardType: TextInputType.emailAddress,

                  decoration: InputDecoration(
                    hintText: "Enter your email",

                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF999999),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // =========================================================
                // PHONE NUMBER
                // =========================================================

                const Text(
                  "Phone Number",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202020),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  keyboardType: TextInputType.phone,

                  decoration: InputDecoration(
                    hintText: "Enter your phone number",

                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF999999),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // =========================================================
                // PASSWORD
                // =========================================================

                const Text(
                  "Password",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202020),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  obscureText: _obscurePassword,

                  decoration: InputDecoration(
                    hintText: "Create a password",

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),

                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                          !_obscurePassword;
                        });
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF999999),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // =========================================================
                // CONFIRM PASSWORD
                // =========================================================

                const Text(
                  "Confirm Password",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202020),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  obscureText: _obscureConfirmPassword,

                  decoration: InputDecoration(
                    hintText: "Confirm your password",

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),

                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                        });
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF999999),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF7352B5),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // =========================================================
                // CREATE ACCOUNT BUTTON
                // =========================================================

                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: ElevatedButton(
                    onPressed: () {
                      print(
                        "Creating account as: $_selectedRole",
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7F1FA),
                      foregroundColor: const Color(0xFF7352B5),
                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),

                        side: const BorderSide(
                          color: Color(0xFFE2D9E7),
                        ),
                      ),
                    ),

                    child: const Text(
                      "Create Account",

                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // =========================================================
                // LOGIN LINK
                // =========================================================

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text(
                      "Already have an account? ",

                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF333333),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        // Navigation will be added later
                      },

                      child: const Text(
                        "Login",

                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF7352B5),
                          fontWeight: FontWeight.w500,
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