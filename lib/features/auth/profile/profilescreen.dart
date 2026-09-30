import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  // ============================================================
  // PERSONAL INFORMATION CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  // ============================================================
  // HEALTH PROFILE CONTROLLERS
  // ============================================================

  final TextEditingController _bloodPressureController =
  TextEditingController();

  final TextEditingController _bloodSugarController =
  TextEditingController();

  final TextEditingController _heartRateController =
  TextEditingController();

  final TextEditingController _spo2Controller =
  TextEditingController();

  final TextEditingController _temperatureController =
  TextEditingController();

  final TextEditingController _weightController =
  TextEditingController();

  final TextEditingController _heightController =
  TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  String _role = "patient";
  String _status = "active";

  Timestamp? _createdAt;

  // Health profile status
  bool _healthProfileExists = false;

  Timestamp? _healthProfileUpdatedAt;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    _bloodPressureController.dispose();
    _bloodSugarController.dispose();
    _heartRateController.dispose();
    _spo2Controller.dispose();
    _temperatureController.dispose();
    _weightController.dispose();
    _heightController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD COMPLETE PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      // ----------------------------------------------------------
      // CHECK LOGIN
      // ----------------------------------------------------------

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showMessage(
          "No user is currently logged in.",
        );

        return;
      }

      final String uid = currentUser.uid;

      debugPrint(
        "Loading profile for UID: $uid",
      );

      // ==========================================================
      // GET USER DOCUMENT
      // ==========================================================

      final DocumentSnapshot<Map<String, dynamic>> userDocument =
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      // ==========================================================
      // USER DOCUMENT
      // ==========================================================

      if (userDocument.exists) {
        final Map<String, dynamic>? data =
        userDocument.data();

        if (data != null) {
          _nameController.text =
              data["name"]?.toString() ?? "";

          _emailController.text =
              data["email"]?.toString() ??
                  currentUser.email ??
                  "";

          _phoneController.text =
              data["phone"]?.toString() ?? "";

          _role =
              data["role"]?.toString() ?? "patient";

          _status =
              data["status"]?.toString() ?? "active";

          final dynamic createdAt =
          data["createdAt"];

          if (createdAt is Timestamp) {
            _createdAt = createdAt;
          }
        }
      } else {
        // --------------------------------------------------------
        // FALLBACK TO FIREBASE AUTH
        // --------------------------------------------------------

        _nameController.text =
            currentUser.displayName ?? "";

        _emailController.text =
            currentUser.email ?? "";

        _phoneController.text = "";

        _role = "patient";
        _status = "active";
      }

      // ==========================================================
      // GET HEALTH PROFILE
      // ==========================================================

      final DocumentSnapshot<Map<String, dynamic>>
      healthProfileDocument =
      await FirebaseFirestore.instance
          .collection("healthProfiles")
          .doc(uid)
          .get();

      // ==========================================================
      // HEALTH PROFILE EXISTS
      // ==========================================================

      if (healthProfileDocument.exists) {
        final Map<String, dynamic>? healthData =
        healthProfileDocument.data();

        if (healthData != null) {
          _healthProfileExists = true;

          // ------------------------------------------------------
          // BLOOD PRESSURE
          // ------------------------------------------------------

          _bloodPressureController.text =
              healthData["bloodPressure"]?.toString() ?? "";

          // ------------------------------------------------------
          // BLOOD SUGAR
          // ------------------------------------------------------

          _bloodSugarController.text =
              healthData["bloodSugar"]?.toString() ?? "";

          // ------------------------------------------------------
          // HEART RATE
          // ------------------------------------------------------

          _heartRateController.text =
              healthData["heartRate"]?.toString() ?? "";

          // ------------------------------------------------------
          // SPO2
          // ------------------------------------------------------

          _spo2Controller.text =
              healthData["spo2"]?.toString() ?? "";

          // ------------------------------------------------------
          // TEMPERATURE
          // ------------------------------------------------------

          _temperatureController.text =
              healthData["temperature"]?.toString() ?? "";

          // ------------------------------------------------------
          // WEIGHT
          // ------------------------------------------------------

          _weightController.text =
              healthData["weight"]?.toString() ?? "";

          // ------------------------------------------------------
          // HEIGHT
          // ------------------------------------------------------

          _heightController.text =
              healthData["height"]?.toString() ?? "";

          // ------------------------------------------------------
          // UPDATED AT
          // ------------------------------------------------------

          final dynamic updatedAt =
          healthData["updatedAt"];

          if (updatedAt is Timestamp) {
            _healthProfileUpdatedAt = updatedAt;
          }
        }
      } else {
        // --------------------------------------------------------
        // HEALTH PROFILE DOES NOT EXIST
        // --------------------------------------------------------

        _healthProfileExists = false;

        _clearHealthControllers();

        debugPrint(
          "Health profile does not exist.",
        );
      }

      // ==========================================================
      // FINISH LOADING
      // ==========================================================

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        "Patient profile loaded successfully.",
      );
    } catch (e) {
      debugPrint(
        "Error loading profile: $e",
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        "Unable to load your profile.",
      );
    }
  }

  // ============================================================
  // CLEAR HEALTH CONTROLLERS
  // ============================================================

  void _clearHealthControllers() {
    _bloodPressureController.clear();
    _bloodSugarController.clear();
    _heartRateController.clear();
    _spo2Controller.clear();
    _temperatureController.clear();
    _weightController.clear();
    _heightController.clear();
  }

  // ============================================================
  // SAVE COMPLETE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    // ==========================================================
    // PERSONAL INFORMATION
    // ==========================================================

    final String name =
    _nameController.text.trim();

    final String phone =
    _phoneController.text.trim();

    // ==========================================================
    // VALIDATION - NAME
    // ==========================================================

    if (name.isEmpty) {
      _showMessage(
        "Name cannot be empty.",
      );
      return;
    }

    if (name.length < 3) {
      _showMessage(
        "Please enter a valid name.",
      );
      return;
    }

    // ==========================================================
    // VALIDATION - PHONE
    // ==========================================================

    if (phone.isEmpty) {
      _showMessage(
        "Phone number cannot be empty.",
      );
      return;
    }

    if (phone.length < 10) {
      _showMessage(
        "Please enter a valid phone number.",
      );
      return;
    }

    // ==========================================================
    // GET CURRENT USER
    // ==========================================================

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        "You are not logged in.",
      );
      return;
    }

    final String uid = currentUser.uid;

    setState(() {
      _isSaving = true;
    });

    try {
      // ========================================================
      // UPDATE USER DOCUMENT
      // ========================================================

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(
        {
          "name": name,
          "phone": phone,
        },
        SetOptions(merge: true),
      );

      // ========================================================
      // UPDATE FIREBASE AUTH DISPLAY NAME
      // ========================================================

      await currentUser.updateDisplayName(name);

      // ========================================================
      // HEALTH PROFILE VALUES
      // ========================================================

      final String bloodPressure =
      _bloodPressureController.text.trim();

      final String bloodSugar =
      _bloodSugarController.text.trim();

      final String heartRate =
      _heartRateController.text.trim();

      final String spo2 =
      _spo2Controller.text.trim();

      final String temperature =
      _temperatureController.text.trim();

      final String weight =
      _weightController.text.trim();

      final String height =
      _heightController.text.trim();

      // ========================================================
      // CALCULATE BMI
      // ========================================================

      double? bmi;

      final double? weightValue =
      double.tryParse(weight);

      final double? heightValue =
      double.tryParse(height);

      if (weightValue != null &&
          heightValue != null &&
          weightValue > 0 &&
          heightValue > 0) {
        final double heightInMeters =
            heightValue / 100;

        double rawBmi = weightValue / (heightInMeters * heightInMeters);
        bmi = double.parse(rawBmi.toStringAsFixed(2));
      }

      // ========================================================
      // CREATE / UPDATE HEALTH PROFILE
      // ========================================================

      await FirebaseFirestore.instance
          .collection("healthProfiles")
          .doc(uid)
          .set(
        {
          "uid": uid,

          // ----------------------------------------------------
          // HEALTH INFORMATION
          // ----------------------------------------------------

          "bloodPressure":
          bloodPressure.isEmpty
              ? null
              : bloodPressure,

          "bloodSugar":
          bloodSugar.isEmpty
              ? null
              : double.tryParse(
            bloodSugar,
          ),

          "heartRate":
          heartRate.isEmpty
              ? null
              : int.tryParse(
            heartRate,
          ),

          "spo2":
          spo2.isEmpty
              ? null
              : double.tryParse(
            spo2,
          ),

          "temperature":
          temperature.isEmpty
              ? null
              : double.tryParse(
            temperature,
          ),

          "weight":
          weight.isEmpty
              ? null
              : double.tryParse(
            weight,
          ),

          "height":
          height.isEmpty
              ? null
              : double.tryParse(
            height,
          ),

          "bmi": bmi,

          // ----------------------------------------------------
          // TIMESTAMP
          // ----------------------------------------------------

          "updatedAt":
          FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isEditing = false;
        _healthProfileExists = true;
      });

      _showSuccessMessage(
        "Profile updated successfully!",
      );

      // --------------------------------------------------------
      // RELOAD DATA
      // --------------------------------------------------------

      await _loadProfile();
    } catch (e) {
      debugPrint(
        "Error saving profile: $e",
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        "Unable to update profile. Please try again.",
      );
    }
  }

  // ============================================================
  // CANCEL EDIT
  // ============================================================

  Future<void> _cancelEdit() async {
    setState(() {
      _isEditing = false;
    });

    await _loadProfile();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
        const Color(0xFF168A62),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF333044),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Color(0xFF242044),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: false,
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6335D6),
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(20),

          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 700,
              ),

              child: Column(
                children: [
                  _buildProfileHeader(),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildPersonalInformation(),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildHealthInformation(),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildAccountInformation(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(24),

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
            offset:
            const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        children: [
          // ------------------------------------------------------
          // PROFILE ICON
          // ------------------------------------------------------

          Container(
            height: 90,
            width: 90,

            decoration: BoxDecoration(
              gradient:
              const LinearGradient(
                colors: [
                  Color(0xFF7352B5),
                  Color(0xFF5B3BA5),
                ],
                begin:
                Alignment.topLeft,
                end:
                Alignment.bottomRight,
              ),

              shape:
              BoxShape.circle,

              boxShadow: [
                BoxShadow(
                  color:
                  const Color(0xFF7352B5)
                      .withOpacity(0.20),
                  blurRadius: 18,
                  offset:
                  const Offset(0, 8),
                ),
              ],
            ),

            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),

          const SizedBox(height: 15),

          // ------------------------------------------------------
          // NAME
          // ------------------------------------------------------

          Text(
            _nameController.text.isEmpty
                ? "Patient"
                : _nameController.text,

            textAlign:
            TextAlign.center,

            style:
            const TextStyle(
              fontSize: 23,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF202033),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _emailController.text,

            textAlign:
            TextAlign.center,

            style:
            const TextStyle(
              fontSize: 14,
              color:
              Color(0xFF777384),
            ),
          ),

          const SizedBox(height: 13),

          // ------------------------------------------------------
          // ROLE BADGE
          // ------------------------------------------------------

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color:
              const Color(0xFFF0EBFF),

              borderRadius:
              BorderRadius.circular(20),
            ),

            child: Row(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                const Icon(
                  Icons
                      .person_outline_rounded,
                  color:
                  Color(0xFF6335D6),
                  size: 17,
                ),

                const SizedBox(width: 6),

                Text(
                  _role.toUpperCase(),

                  style:
                  const TextStyle(
                    color:
                    Color(0xFF6335D6),
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  Widget _buildPersonalInformation() {
    return _profileCard(
      title: "Personal Information",

      icon:
      Icons.person_outline_rounded,

      child: Column(
        children: [
          _buildEditableField(
            label: "Full Name",
            controller:
            _nameController,
            icon:
            Icons.person_outline_rounded,
            enabled:
            _isEditing,
            keyboardType:
            TextInputType.name,
          ),

          const SizedBox(height: 18),

          _buildEditableField(
            label: "Email Address",
            controller:
            _emailController,
            icon:
            Icons.email_outlined,
            enabled: false,
            keyboardType:
            TextInputType.emailAddress,
          ),

          const SizedBox(height: 18),

          _buildEditableField(
            label: "Phone Number",
            controller:
            _phoneController,
            icon:
            Icons.phone_outlined,
            enabled:
            _isEditing,
            keyboardType:
            TextInputType.phone,
          ),

          const SizedBox(height: 25),

          _buildEditButtons(),
        ],
      ),
    );
  }

  // ============================================================
  // HEALTH INFORMATION
  // ============================================================

  Widget _buildHealthInformation() {
    return _profileCard(
      title: "Health Information",

      icon:
      Icons.health_and_safety_outlined,

      child: Column(
        children: [
          // ------------------------------------------------------
          // PROFILE STATUS
          // ------------------------------------------------------

          Container(
            width: double.infinity,

            padding:
            const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: _healthProfileExists
                  ? const Color(0xFFEAF8F1)
                  : const Color(0xFFFFF7E8),

              borderRadius:
              BorderRadius.circular(10),
            ),

            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Icon(
                  _healthProfileExists
                      ? Icons
                      .check_circle_outline
                      : Icons
                      .info_outline,

                  size: 20,

                  color:
                  _healthProfileExists
                      ? const Color(
                    0xFF168A62,
                  )
                      : const Color(
                    0xFFB87500,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    _healthProfileExists
                        ? "Health profile is available."
                        : "Your health profile is empty. "
                        "Add your health information to "
                        "complete your profile.",

                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color:
                      _healthProfileExists
                          ? const Color(
                        0xFF168A62,
                      )
                          : const Color(
                        0xFF8A6200,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ------------------------------------------------------
          // BLOOD PRESSURE
          // ------------------------------------------------------

          _buildHealthField(
            label: "Blood Pressure",
            controller:
            _bloodPressureController,
            hintText:
            "Example: 120/80",
            unit: "mmHg",
            icon:
            Icons.monitor_heart_outlined,
            keyboardType:
            TextInputType.text,
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // BLOOD SUGAR
          // ------------------------------------------------------

          _buildHealthField(
            label: "Blood Sugar",
            controller:
            _bloodSugarController,
            hintText:
            "Enter blood sugar",
            unit: "mg/dL",
            icon:
            Icons.water_drop_outlined,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // HEART RATE
          // ------------------------------------------------------

          _buildHealthField(
            label: "Heart Rate",
            controller:
            _heartRateController,
            hintText:
            "Enter heart rate",
            unit: "bpm",
            icon:
            Icons.favorite_border,
            keyboardType:
            TextInputType.number,
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // SPO2
          // ------------------------------------------------------

          _buildHealthField(
            label: "SpO₂",
            controller:
            _spo2Controller,
            hintText:
            "Enter SpO₂",
            unit: "%",
            icon:
            Icons.air_outlined,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // TEMPERATURE
          // ------------------------------------------------------

          _buildHealthField(
            label: "Temperature",
            controller:
            _temperatureController,
            hintText:
            "Enter temperature",
            unit: "°F",
            icon:
            Icons.thermostat_outlined,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // WEIGHT
          // ------------------------------------------------------

          _buildHealthField(
            label: "Weight",
            controller:
            _weightController,
            hintText:
            "Enter weight",
            unit: "kg",
            icon:
            Icons.monitor_weight_outlined,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // HEIGHT
          // ------------------------------------------------------

          _buildHealthField(
            label: "Height",
            controller:
            _heightController,
            hintText:
            "Enter height",
            unit: "cm",
            icon:
            Icons.height,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------
          // BMI
          // ------------------------------------------------------

          _buildBMICard(),

          // ------------------------------------------------------
          // LAST UPDATED
          // ------------------------------------------------------

          if (_healthProfileUpdatedAt !=
              null) ...[
            const SizedBox(height: 18),

            Align(
              alignment:
              Alignment.centerLeft,

              child: Text(
                "Last updated: "
                    "${_formatDateTime(_healthProfileUpdatedAt!)}",

                style:
                const TextStyle(
                  fontSize: 11,
                  color:
                  Color(0xFF8B8795),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HEALTH FIELD
  // ============================================================

  Widget _buildHealthField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String unit,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style:
          const TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
            color:
            Color(0xFF292637),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,

          enabled: _isEditing,

          keyboardType:
          keyboardType,

          style:
          const TextStyle(
            fontSize: 14,
            color:
            Color(0xFF292637),
          ),

          decoration:
          InputDecoration(
            hintText: hintText,

            hintStyle:
            const TextStyle(
              fontSize: 13,
              color:
              Color(0xFFA09BAA),
            ),

            prefixIcon:
            Icon(
              icon,
              color:
              const Color(
                0xFF8B8499,
              ),
              size: 21,
            ),

            suffixText: unit,

            suffixStyle:
            const TextStyle(
              fontSize: 12,
              color:
              Color(0xFF777384),
            ),

            filled: true,

            fillColor: _isEditing
                ? const Color(
              0xFFFAF9FC,
            )
                : const Color(
              0xFFF1F0F4,
            ),

            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFFE3DFEA),
              ),
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFFE3DFEA),
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFF7352B5),
                width: 1.7,
              ),
            ),

            disabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFFE3DFEA),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BMI CARD
  // ============================================================

  Widget _buildBMICard() {
    final double? weight =
    double.tryParse(
      _weightController.text.trim(),
    );

    final double? height =
    double.tryParse(
      _heightController.text.trim(),
    );

    double? bmi;

    if (weight != null &&
        height != null &&
        weight > 0 &&
        height > 0) {
      final double heightInMeters =
          height / 100;

      bmi = weight /
          (heightInMeters *
              heightInMeters);
    }

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
        const Color(0xFFF7F3FF),

        borderRadius:
        BorderRadius.circular(12),

        border: Border.all(
          color:
          const Color(0xFFE5DAFA),
        ),
      ),

      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,

            decoration:
            const BoxDecoration(
              color:
              Color(0xFFEDE2FF),
              shape:
              BoxShape.circle,
            ),

            child: const Icon(
              Icons.analytics_outlined,
              color:
              Color(0xFF6335D6),
              size: 23,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  "BMI",

                  style:
                  TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF777384),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Calculated from height and weight",

                  style:
                  TextStyle(
                    fontSize: 11,
                    color:
                    Color(0xFF9994A4),
                  ),
                ),
              ],
            ),
          ),

          Text(
            bmi == null
                ? "Not available"
                : bmi.toStringAsFixed(1),

            style:
            const TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF6335D6),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT BUTTONS
  // ============================================================

  Widget _buildEditButtons() {
    if (!_isEditing) {
      return SizedBox(
        width: double.infinity,
        height: 50,

        child:
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },

          icon: const Icon(
            Icons.edit_outlined,
            size: 19,
          ),

          label: const Text(
            "Edit Profile",
            style:
            TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          style:
          ElevatedButton.styleFrom(
            backgroundColor:
            const Color(
              0xFF6335D6,
            ),

            foregroundColor:
            Colors.white,

            elevation: 0,

            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child:
          OutlinedButton(
            onPressed:
            _isSaving
                ? null
                : _cancelEdit,

            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              const Color(
                0xFF6335D6,
              ),

              side:
              const BorderSide(
                color:
                Color(
                  0xFF6335D6,
                ),
              ),

              minimumSize:
              const Size(
                0,
                50,
              ),

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
            ),

            child:
            const Text(
              "Cancel",
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child:
          ElevatedButton.icon(
            onPressed:
            _isSaving
                ? null
                : _saveProfile,

            icon: _isSaving
                ? const SizedBox(
              height: 18,
              width: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                Colors.white,
              ),
            )
                : const Icon(
              Icons.save_outlined,
              size: 19,
            ),

            label: Text(
              _isSaving
                  ? "Saving..."
                  : "Save Changes",
            ),

            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              const Color(
                0xFF6335D6,
              ),

              foregroundColor:
              Colors.white,

              elevation: 0,

              minimumSize:
              const Size(
                0,
                50,
              ),

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACCOUNT INFORMATION
  // ============================================================

  Widget _buildAccountInformation() {
    return _profileCard(
      title: "Account Information",

      icon:
      Icons.verified_user_outlined,

      child: Column(
        children: [
          _accountRow(
            "Account Type",
            _role.toUpperCase(),
            Icons.badge_outlined,
          ),

          const Divider(
            height: 28,
            color:
            Color(0xFFEDE9F3),
          ),

          _accountRow(
            "Account Status",
            _status.toUpperCase(),
            Icons.verified_outlined,
            valueColor:
            _status.toLowerCase() ==
                "active"
                ? const Color(
              0xFF168A62,
            )
                : Colors.red,
          ),

          const Divider(
            height: 28,
            color:
            Color(0xFFEDE9F3),
          ),

          _accountRow(
            "User ID",
            _getShortUid(),
            Icons.fingerprint,
          ),

          if (_createdAt !=
              null) ...[
            const Divider(
              height: 28,
              color:
              Color(0xFFEDE9F3),
            ),

            _accountRow(
              "Account Created",
              _formatDate(
                _createdAt!,
              ),
              Icons
                  .calendar_today_outlined,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _profileCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(18),

        border: Border.all(
          color:
          const Color(0xFFE4E0EF),
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.025,
            ),
            blurRadius: 15,
            offset:
            const Offset(0, 6),
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

                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF0EBFF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),

                child: Icon(
                  icon,
                  color:
                  const Color(
                    0xFF7352B5,
                  ),
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  title,

                  style:
                  const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF252332),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // EDITABLE FIELD
  // ============================================================

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style:
          const TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
            color:
            Color(0xFF292637),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType:
          keyboardType,

          style:
          const TextStyle(
            fontSize: 14,
            color:
            Color(0xFF292637),
          ),

          decoration:
          InputDecoration(
            prefixIcon:
            Icon(
              icon,
              color:
              const Color(
                0xFF8B8499,
              ),
              size: 21,
            ),

            filled: true,

            fillColor: enabled
                ? const Color(
              0xFFFAF9FC,
            )
                : const Color(
              0xFFF1F0F4,
            ),

            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFFE3DFEA),
              ),
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFFE3DFEA),
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFF7352B5),
                width: 1.7,
              ),
            ),

            disabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFFE3DFEA),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACCOUNT ROW
  // ============================================================

  Widget _accountRow(
      String title,
      String value,
      IconData icon, {
        Color? valueColor,
      }) {
    return Row(
      children: [
        Icon(
          icon,
          color:
          const Color(0xFF7352B5),
          size: 21,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,

            style:
            const TextStyle(
              fontSize: 13,
              color:
              Color(0xFF777384),
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,

            textAlign:
            TextAlign.right,

            style:
            TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
              color:
              valueColor ??
                  const Color(
                    0xFF292637,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHORT UID
  // ============================================================

  String _getShortUid() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return "N/A";
    }

    final String uid =
        user.uid;

    if (uid.length <= 14) {
      return uid;
    }

    return "${uid.substring(0, 8)}...";
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
      Timestamp timestamp,
      ) {
    final DateTime date =
    timestamp.toDate();

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  // ============================================================
  // FORMAT DATE + TIME
  // ============================================================

  String _formatDateTime(
      Timestamp timestamp,
      ) {
    final DateTime date =
    timestamp.toDate();

    final String hour =
    date.hour
        .toString()
        .padLeft(2, '0');

    final String minute =
    date.minute
        .toString()
        .padLeft(2, '0');

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} at "
        "$hour:$minute";
  }
}