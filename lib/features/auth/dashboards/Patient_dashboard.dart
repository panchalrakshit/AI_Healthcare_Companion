import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ai_healthcompanion_using_flutter/features/auth/appointments/appointmentscreen.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/healthrecords/health_records_screen.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/login/login_screen.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/profile/profilescreen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  // ============================================================
  // VARIABLES
  // ============================================================

  int _selectedIndex = 0;

  bool _isLoading = true;

  // ============================================================
  // USER DATA
  // ============================================================

  String _userName = "Patient";
  String _userEmail = "";
  String _userPhone = "";

  // ============================================================
  // HEALTH PROFILE DATA
  // ============================================================

  String _bloodPressure = "";
  String _bloodSugar = "";
  String _heartRate = "";
  String _spo2 = "";
  String _temperature = "";
  String _weight = "";
  String _bmi = "";
  String _lastCheckup = "";

  bool _healthProfileExists = false;

  // ============================================================
  // MENU
  // ============================================================

  final List<String> _menuItems = [
    "Dashboard",
    "My Profile",
    "Health Records",
    "Predictions",
    "Appointments",
    "Notifications",
    "Profile Settings",
  ];

  final List<IconData> _menuIcons = [
    Icons.dashboard_outlined,
    Icons.person_outline,
    Icons.folder_outlined,
    Icons.analytics_outlined,
    Icons.calendar_month_outlined,
    Icons.notifications_none_outlined,
    Icons.settings_outlined,
  ];

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  // ============================================================
  // LOAD PATIENT DATA
  // ============================================================

  Future<void> _loadPatientData() async {
    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      final String uid = currentUser.uid;

      debugPrint("========================================");
      debugPrint("Loading Patient Dashboard");
      debugPrint("UID: $uid");
      debugPrint("========================================");

      // ----------------------------------------------------------
      // USER DOCUMENT
      // ----------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>> userDocument =
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      // ----------------------------------------------------------
      // HEALTH PROFILE
      // ----------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>>
      healthProfileDocument =
      await FirebaseFirestore.instance
          .collection("healthProfiles")
          .doc(uid)
          .get();

      String userName =
          currentUser.displayName ?? "Patient";

      String userEmail =
          currentUser.email ?? "";

      String userPhone = "";

      if (userDocument.exists) {
        final Map<String, dynamic>? userData =
        userDocument.data();

        if (userData != null) {
          userName =
              userData["name"]?.toString() ??
                  userName;

          userEmail =
              userData["email"]?.toString() ??
                  userEmail;

          userPhone =
              userData["phone"]?.toString() ??
                  "";
        }
      }

      // ----------------------------------------------------------
      // HEALTH DATA
      // ----------------------------------------------------------

      String bloodPressure = "";
      String bloodSugar = "";
      String heartRate = "";
      String spo2 = "";
      String temperature = "";
      String weight = "";
      String bmi = "";
      String lastCheckup = "";

      final bool healthProfileExists =
          healthProfileDocument.exists;

      if (healthProfileDocument.exists) {
        final Map<String, dynamic>? healthData =
        healthProfileDocument.data();

        if (healthData != null) {
          bloodPressure =
              _readHealthValue(
                healthData["bloodPressure"],
              );

          bloodSugar =
              _readHealthValue(
                healthData["bloodSugar"],
              );

          heartRate =
              _readHealthValue(
                healthData["heartRate"],
              );

          spo2 =
              _readHealthValue(
                healthData["spo2"],
              );

          temperature =
              _readHealthValue(
                healthData["temperature"],
              );

          weight =
              _readHealthValue(
                healthData["weight"],
              );

          bmi =
              _readHealthValue(
                healthData["bmi"],
              );

          lastCheckup =
              _readDateValue(
                healthData["lastCheckup"],
              );
        }
      }

      if (!mounted) return;

      setState(() {
        _userName = userName;
        _userEmail = userEmail;
        _userPhone = userPhone;

        _bloodPressure = bloodPressure;
        _bloodSugar = bloodSugar;
        _heartRate = heartRate;
        _spo2 = spo2;
        _temperature = temperature;
        _weight = weight;
        _bmi = bmi;
        _lastCheckup = lastCheckup;

        _healthProfileExists =
            healthProfileExists;

        _isLoading = false;
      });

      debugPrint(
        "Patient dashboard data loaded successfully.",
      );
    } catch (e) {
      debugPrint(
        "Error loading patient data: $e",
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to load your profile information.",
          ),
        ),
      );
    }
  }

  // ============================================================
  // SAFE HEALTH VALUE
  // ============================================================

  String _readHealthValue(dynamic value) {
    if (value == null) {
      return "";
    }

    if (value is String) {
      return value.trim();
    }

    if (value is num) {
      return value.toString();
    }

    return value.toString();
  }

  // ============================================================
  // SAFE DATE VALUE
  // ============================================================

  String _readDateValue(dynamic value) {
    if (value == null) {
      return "";
    }

    if (value is Timestamp) {
      final DateTime date = value.toDate();

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    }

    if (value is DateTime) {
      return "${value.day.toString().padLeft(2, '0')}/"
          "${value.month.toString().padLeft(2, '0')}/"
          "${value.year}";
    }

    return value.toString();
  }

  // ============================================================
  // VALUE CHECK
  // ============================================================

  bool _hasValue(String value) {
    return value.trim().isNotEmpty;
  }

  // ============================================================
  // HEALTH PROFILE COMPLETION
  // ============================================================

  bool _isHealthProfileComplete() {
    return _hasValue(_bloodPressure) &&
        _hasValue(_bloodSugar) &&
        _hasValue(_heartRate) &&
        _hasValue(_spo2) &&
        _hasValue(_temperature) &&
        _hasValue(_weight) &&
        _hasValue(_bmi) &&
        _hasValue(_lastCheckup);
  }

  // ============================================================
  // DISPLAY VALUE
  // ============================================================

  String _displayValue(String value) {
    if (value.trim().isEmpty) {
      return "Not available";
    }

    return value;
  }

  // ============================================================
  // NOTIFICATION STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  _notificationStream() {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("notifications")
        .where(
      "patientId",
      isEqualTo: currentUser.uid,
    )
        .orderBy(
      "createdAt",
      descending: true,
    )
        .snapshots();
  }

  // ============================================================
  // UNREAD NOTIFICATION STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  _unreadNotificationStream() {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("notifications")
        .where(
      "patientId",
      isEqualTo: currentUser.uid,
    )
        .where(
      "isRead",
      isEqualTo: false,
    )
        .snapshots();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFDFBFF),
      body: LayoutBuilder(
        builder: (
            context,
            constraints,
            ) {
          final bool isMobile =
              constraints.maxWidth < 1000;

          if (isMobile) {
            return _buildMobileLayout();
          }

          return _buildDesktopLayout();
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP LAYOUT
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildSidebar(),

        Expanded(
          child: SafeArea(
            child: _buildSelectedContent(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELECTED CONTENT
  // ============================================================

  Widget _buildSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            28,
            24,
            32,
            32,
          ),
          child: _buildDashboardContent(),
        );

      case 1:
        return const PatientProfile();

      case 2:
        return const HealthRecordsScreen();

      case 3:
        return _buildComingSoonScreen(
          title: "AI Predictions",
          subtitle:
          "AI-powered health predictions will be available here.",
          icon: Icons.analytics_outlined,
        );

      case 4:
        return const AppointmentsScreen();

      case 5:
        return _buildNotificationsScreen();

      case 6:
        return _buildComingSoonScreen(
          title: "Profile Settings",
          subtitle:
          "Your account and profile settings will appear here.",
          icon: Icons.settings_outlined,
        );

      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            28,
            24,
            32,
            32,
          ),
          child: _buildDashboardContent(),
        );
    }
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFDFBFF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "HealthCompanion",
          style: TextStyle(
            color: Color(0xFF242044),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme:
        const IconThemeData(
          color: Color(0xFF5B32C8),
          size: 26,
        ),
      ),

      drawer: Drawer(
        child: _buildSidebar(),
      ),

      body: SafeArea(
        child: _buildSelectedContent(),
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 225,

      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFEAE6F2),
          ),
        ),
      ),

      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 22),

            Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 18,
              ),

              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,

                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFEFE7FF,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: const Icon(
                      Icons.local_hospital,
                      color:
                      Color(0xFF6236D5),
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      "HealthCompanion",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF22203A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 38),

            Expanded(
              child: ListView.builder(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                ),

                itemCount:
                _menuItems.length,

                itemBuilder:
                    (context, index) {
                  return _buildMenuItem(
                    index,
                    _menuItems[index],
                    _menuIcons[index],
                  );
                },
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                12,
                0,
                12,
                22,
              ),

              child: _buildMenuItem(
                -1,
                "Logout",
                Icons.logout_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _buildMenuItem(
      int index,
      String title,
      IconData icon,
      ) {
    final bool selected =
        _selectedIndex == index;

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),

      child: InkWell(
        borderRadius:
        BorderRadius.circular(10),

        onTap: () {
          if (index == -1) {
            _showLogoutDialog();
            return;
          }

          setState(() {
            _selectedIndex = index;
          });

          if (MediaQuery.of(context)
              .size
              .width <
              1000) {
            Navigator.pop(context);
          }
        },

        child: Container(
          height: 50,

          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
          ),

          decoration:
          BoxDecoration(
            color: selected
                ? const Color(
              0xFF6335D6,
            )
                : Colors.transparent,

            borderRadius:
            BorderRadius.circular(
              10,
            ),
          ),

          child: Row(
            children: [
              Icon(
                icon,
                size: 23,
                color: selected
                    ? Colors.white
                    : const Color(
                  0xFF5E5A73,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 15,

                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,

                    color: selected
                        ? Colors.white
                        : const Color(
                      0xFF4A475C,
                    ),
                  ),
                ),
              ),

              // ------------------------------------------------
              // REAL UNREAD NOTIFICATION BADGE
              // ------------------------------------------------

              if (title == "Notifications")
                StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream:
                  _unreadNotificationStream(),

                  builder:
                      (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final int count =
                        snapshot.data!.docs.length;

                    final String badgeText =
                    count > 99
                        ? "99+"
                        : count.toString();

                    return Container(
                      constraints:
                      const BoxConstraints(
                        minWidth: 21,
                      ),

                      height: 21,

                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),

                      alignment:
                      Alignment.center,

                      decoration:
                      const BoxDecoration(
                        color:
                        Color(0xFFFF4D5A),
                        shape:
                        BoxShape.circle,
                      ),

                      child: Text(
                        badgeText,
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 10,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS SCREEN
  // ============================================================

  Widget _buildNotificationsScreen() {
    return Container(
      color: const Color(0xFFFDFBFF),

      child: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: _notificationStream(),

        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(
                color:
                Color(0xFF6335D6),
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint(
              "Notification error: ${snapshot.error}",
            );

            return _buildNotificationError();
          }

          final records =
              snapshot.data?.docs ?? [];

          return Column(
            children: [
              _buildNotificationHeader(
                records,
              ),

              Expanded(
                child: records.isEmpty
                    ? _buildEmptyNotifications()
                    : ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(
                    28,
                    20,
                    32,
                    32,
                  ),
                  itemCount:
                  records.length,
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    return Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        bottom: 14,
                      ),
                      child:
                      _buildNotificationCard(
                        records[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // NOTIFICATION HEADER
  // ============================================================

  Widget _buildNotificationHeader(
      List<QueryDocumentSnapshot<
          Map<String, dynamic>>>
      notifications,
      ) {
    final int unreadCount =
        notifications.where((doc) {
          final data = doc.data();

          return data["isRead"] == false;
        }).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        28,
        24,
        32,
        20,
      ),

      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8E2F2),
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,

            decoration:
            const BoxDecoration(
              color: Color(0xFFEFE7FF),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF6335D6),
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                const Text(
                  "Notifications",
                  style: TextStyle(
                    color:
                    Color(0xFF242044),
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  unreadCount == 0
                      ? "You're all caught up."
                      : "$unreadCount unread notification${unreadCount == 1 ? '' : 's'}",

                  style:
                  const TextStyle(
                    color:
                    Color(0xFF777384),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          if (unreadCount > 0)
            TextButton(
              onPressed:
              _markAllNotificationsAsRead,

              child: const Text(
                "Mark all as read",
                style: TextStyle(
                  color:
                  Color(0xFF6335D6),
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard(
      QueryDocumentSnapshot<
          Map<String, dynamic>>
      document,
      ) {
    final Map<String, dynamic> data =
    document.data();

    final String title =
        data["title"]?.toString() ??
            "Notification";

    final String message =
        data["message"]?.toString() ??
            "";

    final String type =
        data["type"]?.toString() ??
            "general";

    final bool isRead =
        data["isRead"] == true;

    final Timestamp? createdAt =
    data["createdAt"] is Timestamp
        ? data["createdAt"]
    as Timestamp
        : null;

    return InkWell(
      borderRadius:
      BorderRadius.circular(15),

      onTap: () {
        if (!isRead) {
          _markNotificationAsRead(
            document.id,
          );
        }

        _showNotificationDetails(
          document,
        );
      },

      child: Container(
        padding:
        const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : const Color(0xFFFAF7FF),

          borderRadius:
          BorderRadius.circular(15),

          border: Border.all(
            color: isRead
                ? const Color(
              0xFFE4E0EF,
            )
                : const Color(
              0xFFDCCCF8,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.025),
              blurRadius: 12,
              offset:
              const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Container(
              height: 48,
              width: 48,

              decoration: BoxDecoration(
                color:
                _notificationIconBackground(
                  type,
                ),
                shape:
                BoxShape.circle,
              ),

              child: Icon(
                _notificationIcon(type),
                color:
                _notificationIconColor(
                  type,
                ),
                size: 23,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Text(
                          title,

                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,

                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                            isRead
                                ? FontWeight
                                .w600
                                : FontWeight
                                .w700,

                            color:
                            const Color(
                              0xFF252332,
                            ),
                          ),
                        ),
                      ),

                      if (!isRead)
                        Container(
                          margin:
                          const EdgeInsets
                              .only(
                            left: 8,
                            top: 4,
                          ),

                          height: 9,
                          width: 9,

                          decoration:
                          const BoxDecoration(
                            color:
                            Color(
                              0xFF6335D6,
                            ),
                            shape:
                            BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    message,

                    maxLines: 3,
                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color:
                      Color(0xFF777384),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      if (createdAt != null)
                        Text(
                          _formatNotificationDate(
                            createdAt,
                          ),

                          style:
                          const TextStyle(
                            fontSize: 11,
                            color:
                            Color(
                              0xFF9A95A5,
                            ),
                          ),
                        ),

                      const Spacer(),

                      PopupMenuButton<
                          String>(
                        padding:
                        EdgeInsets.zero,

                        icon: const Icon(
                          Icons.more_vert,
                          size: 20,
                          color:
                          Color(
                            0xFF777384,
                          ),
                        ),

                        onSelected:
                            (value) {
                          if (value ==
                              "read") {
                            _markNotificationAsRead(
                              document.id,
                            );
                          }

                          if (value ==
                              "delete") {
                            _confirmDeleteNotification(
                              document.id,
                              title,
                            );
                          }
                        },

                        itemBuilder:
                            (context) {
                          return [
                            if (!isRead)
                              const PopupMenuItem(
                                value:
                                "read",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .done_outlined,
                                      size: 18,
                                    ),
                                    SizedBox(
                                      width:
                                      10,
                                    ),
                                    Text(
                                      "Mark as read",
                                    ),
                                  ],
                                ),
                              ),

                            const PopupMenuItem(
                              value:
                              "delete",
                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .delete_outline,
                                    size: 18,
                                    color:
                                    Colors.red,
                                  ),
                                  SizedBox(
                                    width:
                                    10,
                                  ),
                                  Text(
                                    "Delete",
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY NOTIFICATIONS
  // ============================================================

  Widget _buildEmptyNotifications() {
    return Center(
      child: SingleChildScrollView(
        padding:
        const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Container(
              height: 100,
              width: 100,

              decoration:
              const BoxDecoration(
                color:
                Color(0xFFF0EBFF),
                shape:
                BoxShape.circle,
              ),

              child: const Icon(
                Icons
                    .notifications_none_outlined,
                color:
                Color(0xFF6335D6),
                size: 50,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "No Notifications",

              textAlign:
              TextAlign.center,

              style: TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF252332),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "You don't have any notifications yet.\n"
                  "We'll let you know when something important happens.",

              textAlign:
              TextAlign.center,

              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color:
                Color(0xFF777384),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ERROR
  // ============================================================

  Widget _buildNotificationError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 55,
            ),

            const SizedBox(height: 18),

            const Text(
              "Unable to load notifications",

              textAlign:
              TextAlign.center,

              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF252332),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Please check your internet connection "
                  "and Firestore configuration.",

              textAlign:
              TextAlign.center,

              style: TextStyle(
                fontSize: 13,
                color:
                Color(0xFF777384),
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: () {
                setState(() {});
              },

              child:
              const Text(
                "Try Again",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MARK NOTIFICATION AS READ
  // ============================================================

  Future<void> _markNotificationAsRead(
      String notificationId,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc(notificationId)
          .update({
        "isRead": true,
      });
    } catch (e) {
      debugPrint(
        "Error marking notification as read: $e",
      );
    }
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS AS READ
  // ============================================================

  Future<void>
  _markAllNotificationsAsRead() async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>>
      snapshot =
      await FirebaseFirestore.instance
          .collection("notifications")
          .where(
        "patientId",
        isEqualTo: currentUser.uid,
      )
          .where(
        "isRead",
        isEqualTo: false,
      )
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch =
      FirebaseFirestore.instance.batch();

      for (final document
      in snapshot.docs) {
        batch.update(
          document.reference,
          {
            "isRead": true,
          },
        );
      }

      await batch.commit();

      if (mounted) {
        _showSuccessMessage(
          "All notifications marked as read.",
        );
      }
    } catch (e) {
      debugPrint(
        "Error marking all notifications: $e",
      );

      if (mounted) {
        _showMessage(
          "Unable to update notifications.",
        );
      }
    }
  }

  // ============================================================
  // SHOW NOTIFICATION DETAILS
  // ============================================================

  void _showNotificationDetails(
      QueryDocumentSnapshot<
          Map<String, dynamic>>
      document,
      ) {
    final Map<String, dynamic> data =
    document.data();

    final String title =
        data["title"]?.toString() ??
            "Notification";

    final String message =
        data["message"]?.toString() ??
            "";

    final String type =
        data["type"]?.toString() ??
            "general";

    final Timestamp? createdAt =
    data["createdAt"] is Timestamp
        ? data["createdAt"]
    as Timestamp
        : null;

    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                height: 38,
                width: 38,

                decoration:
                BoxDecoration(
                  color:
                  _notificationIconBackground(
                    type,
                  ),
                  shape:
                  BoxShape.circle,
                ),

                child: Icon(
                  _notificationIcon(type),
                  color:
                  _notificationIconColor(
                    type,
                  ),
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          content:
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  message,

                  style:
                  const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color:
                    Color(0xFF5F5A6D),
                  ),
                ),

                if (createdAt != null) ...[
                  const SizedBox(height: 18),

                  Text(
                    "Received: "
                        "${_formatNotificationDate(createdAt)}",

                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Color(0xFF9993A5),
                    ),
                  ),
                ],
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child:
              const Text(
                "Close",
                style: TextStyle(
                  color:
                  Color(0xFF6335D6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  void _confirmDeleteNotification(
      String notificationId,
      String title,
      ) {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete Notification",

            style: TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          content: Text(
            'Are you sure you want to delete "$title"?',

            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child:
              const Text(
                "Cancel",
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await _deleteNotification(
                  notificationId,
                );
              },

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
              ),

              child:
              const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  Future<void> _deleteNotification(
      String notificationId,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc(notificationId)
          .delete();

      if (!mounted) return;

      _showSuccessMessage(
        "Notification deleted.",
      );
    } catch (e) {
      debugPrint(
        "Error deleting notification: $e",
      );

      if (mounted) {
        _showMessage(
          "Unable to delete notification.",
        );
      }
    }
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  IconData _notificationIcon(
      String type,
      ) {
    switch (type.toLowerCase()) {
      case "appointment":
        return Icons.calendar_month_outlined;

      case "health":
        return Icons.favorite_outline;

      case "health_record":
        return Icons.folder_outlined;

      case "prediction":
        return Icons.analytics_outlined;

      case "prescription":
        return Icons.medication_outlined;

      case "warning":
        return Icons.warning_amber_outlined;

      case "success":
        return Icons.check_circle_outline;

      default:
        return Icons.notifications_outlined;
    }
  }

  // ============================================================
  // NOTIFICATION ICON COLOR
  // ============================================================

  Color _notificationIconColor(
      String type,
      ) {
    switch (type.toLowerCase()) {
      case "appointment":
        return const Color(0xFF438EF5);

      case "health":
        return const Color(0xFFE84555);

      case "health_record":
        return const Color(0xFF7042D9);

      case "prediction":
        return const Color(0xFF6335D6);

      case "prescription":
        return const Color(0xFF159653);

      case "warning":
        return const Color(0xFFFF8500);

      case "success":
        return const Color(0xFF168A62);

      default:
        return const Color(0xFF6335D6);
    }
  }

  // ============================================================
  // NOTIFICATION ICON BACKGROUND
  // ============================================================

  Color _notificationIconBackground(
      String type,
      ) {
    switch (type.toLowerCase()) {
      case "appointment":
        return const Color(0xFFE7F0FF);

      case "health":
        return const Color(0xFFFFE8EA);

      case "health_record":
        return const Color(0xFFF0E9FF);

      case "prediction":
        return const Color(0xFFF0EBFF);

      case "prescription":
        return const Color(0xFFE5F6EB);

      case "warning":
        return const Color(0xFFFFF1DF);

      case "success":
        return const Color(0xFFE5F6EB);

      default:
        return const Color(0xFFF0EBFF);
    }
  }

  // ============================================================
  // NOTIFICATION DATE
  // ============================================================

  String _formatNotificationDate(
      Timestamp timestamp,
      ) {
    final DateTime date =
    timestamp.toDate();

    final DateTime now =
    DateTime.now();

    final Duration difference =
    now.difference(date);

    if (difference.inMinutes < 1) {
      return "Just now";
    }

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    }

    if (difference.inHours < 24) {
      return "${difference.inHours} hr ago";
    }

    if (difference.inDays < 7) {
      return "${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago";
    }

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  // ============================================================
  // DASHBOARD CONTENT
  // ============================================================

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 600,
        child: Center(
          child:
          CircularProgressIndicator(
            color:
            Color(0xFF6335D6),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        _buildTopHeader(),

        const SizedBox(height: 26),

        _buildTopCards(),

        const SizedBox(height: 22),

        _buildHealthAndRiskSection(),

        const SizedBox(height: 22),

        _buildPredictionsAndAppointments(),

        const SizedBox(height: 22),

        _buildHealthTip(),

        const SizedBox(height: 22),

        Center(
          child: Text(
            "© 2025 HealthCompanion. All rights reserved.",

            style: TextStyle(
              color:
              Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOP HEADER
  // ============================================================

  Widget _buildTopHeader() {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,

          decoration:
          const BoxDecoration(
            color: Color(0xFFE9E4F8),
            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.person,
            color:
            Color(0xFF5B32C8),
            size: 30,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              const Text(
                "Welcome back,",

                style: TextStyle(
                  color:
                  Color(0xFF777384),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                _userName,

                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,

                style:
                const TextStyle(
                  color:
                  Color(0xFF202033),
                  fontSize: 21,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        // --------------------------------------------------------
        // NOTIFICATION HEADER BUTTON
        // --------------------------------------------------------

        StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream:
          _unreadNotificationStream(),

          builder:
              (context, snapshot) {
            String? badge;

            if (snapshot.hasData &&
                snapshot.data!.docs
                    .isNotEmpty) {
              final int count =
                  snapshot.data!.docs.length;

              badge = count > 99
                  ? "99+"
                  : count.toString();
            }

            return InkWell(
              borderRadius:
              BorderRadius.circular(12),

              onTap: () {
                setState(() {
                  _selectedIndex = 5;
                });
              },

              child: _headerIcon(
                Icons
                    .notifications_none_outlined,
                badge: badge,
              ),
            );
          },
        ),

        const SizedBox(width: 12),

        InkWell(
          borderRadius:
          BorderRadius.circular(12),

          onTap: () {
            setState(() {
              _selectedIndex = 4;
            });
          },

          child: _headerIcon(
            Icons.calendar_month_outlined,
          ),
        ),

        const SizedBox(width: 12),

        Container(
          height: 46,
          width: 46,

          decoration:
          const BoxDecoration(
            color: Color(0xFFEFEAFB),
            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.person,
            color:
            Color(0xFF5B32C8),
            size: 27,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER ICON
  // ============================================================

  Widget _headerIcon(
      IconData icon, {
        String? badge,
      }) {
    return Stack(
      clipBehavior: Clip.none,

      children: [
        Container(
          height: 46,
          width: 46,

          decoration:
          BoxDecoration(
            color: Colors.white,

            borderRadius:
            BorderRadius.circular(12),

            border: Border.all(
              color:
              const Color(0xFFE6E0F1),
            ),
          ),

          child: Icon(
            icon,
            color:
            const Color(0xFF5B32C8),
            size: 24,
          ),
        ),

        if (badge != null)
          Positioned(
            right: -4,
            top: -6,

            child: Container(
              constraints:
              const BoxConstraints(
                minWidth: 20,
              ),

              height: 20,

              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 4,
              ),

              alignment:
              Alignment.center,

              decoration:
              const BoxDecoration(
                color:
                Color(0xFFFF4554),
                shape:
                BoxShape.circle,
              ),

              child: Text(
                badge,

                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 9,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TOP CARDS
  // ============================================================

  Widget _buildTopCards() {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        if (constraints.maxWidth <
            750) {
          return Column(
            children: [
              _buildHealthStatusCard(),

              const SizedBox(
                height: 14,
              ),

              _buildPredictionCard(),

              const SizedBox(
                height: 14,
              ),

              _buildAppointmentCard(),

              const SizedBox(
                height: 14,
              ),

              _buildMedicalRecordsCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Expanded(
              child:
              _buildHealthStatusCard(),
            ),

            const SizedBox(width: 14),

            Expanded(
              child:
              _buildPredictionCard(),
            ),

            const SizedBox(width: 14),

            Expanded(
              child:
              _buildAppointmentCard(),
            ),

            const SizedBox(width: 14),

            Expanded(
              child:
              _buildMedicalRecordsCard(),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HEALTH STATUS CARD
  // ============================================================

  Widget _buildHealthStatusCard() {
    final bool complete =
    _isHealthProfileComplete();

    return _infoCard(
      title: "Health Status",

      titleColor:
      const Color(0xFF149653),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,

        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              mainAxisSize:
              MainAxisSize.min,

              children: [
                Text(
                  complete
                      ? "Complete"
                      : "Not available",

                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize:
                    complete ? 21 : 20,
                    height: 1.15,
                    fontWeight:
                    FontWeight.w700,
                    color: complete
                        ? const Color(
                      0xFF159653,
                    )
                        : const Color(
                      0xFF777384,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  complete
                      ? "Health profile updated"
                      : "Complete your health profile",

                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color:
                    Color(0xFF777384),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _circleIcon(
            complete
                ? Icons.favorite
                : Icons.favorite_border,

            complete
                ? const Color(
              0xFF37A765,
            )
                : const Color(
              0xFF8B8499,
            ),

            complete
                ? const Color(
              0xFFE5F6EB,
            )
                : const Color(
              0xFFF0EEF3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREDICTION CARD
  // ============================================================

  Widget _buildPredictionCard() {
    return _infoCard(
      title: "Last Prediction",

      titleColor:
      const Color(0xFFFF8500),

      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              mainAxisSize:
              MainAxisSize.min,

              children: [
                Text(
                  "Not available",
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 20,
                    height: 1.15,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF777384),
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  "No assessment yet",
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF777384),
                  ),
                ),
              ],
            ),
          ),

          _circleIcon(
            Icons.health_and_safety_outlined,
            const Color(0xFF8B8499),
            const Color(0xFFF0EEF3),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPOINTMENT CARD
  // ============================================================

  Widget _buildAppointmentCard() {
    return _infoCard(
      title:
      "Upcoming Appointment",

      titleColor:
      const Color(0xFF4C91F7),

      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              mainAxisSize:
              MainAxisSize.min,

              children: [
                Text(
                  "No appointment",
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF777384),
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  "No upcoming booking",
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF777384),
                  ),
                ),
              ],
            ),
          ),

          _circleIcon(
            Icons.calendar_month,
            const Color(0xFF438EF5),
            const Color(0xFFE7F0FF),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICAL RECORDS CARD
  // ============================================================

  Widget _buildMedicalRecordsCard() {
    return _infoCard(
      title: "Medical Records",

      titleColor:
      const Color(0xFF7042D9),

      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              mainAxisSize:
              MainAxisSize.min,

              children: [
                Text(
                  "0",

                  style: TextStyle(
                    fontSize: 27,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF262334),
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Total Records",
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF777384),
                  ),
                ),
              ],
            ),
          ),

          _circleIcon(
            Icons.description_outlined,
            const Color(0xFF7042D9),
            const Color(0xFFF0E9FF),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _infoCard({
    required String title,
    required Color titleColor,
    required Widget child,
  }) {
    return Container(
      constraints:
      const BoxConstraints(
        minHeight: 155,
      ),

      padding:
      const EdgeInsets.all(17),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(12),

        border: Border.all(
          color:
          const Color(0xFFE8E2F2),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.025),
            blurRadius: 12,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        mainAxisSize:
        MainAxisSize.min,

        children: [
          Text(
            title,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,

            style: TextStyle(
              fontSize: 13,
              color: titleColor,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // CIRCLE ICON
  // ============================================================

  Widget _circleIcon(
      IconData icon,
      Color iconColor,
      Color backgroundColor,
      ) {
    return Container(
      height: 43,
      width: 43,

      decoration:
      BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),

      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }

  // ============================================================
  // HEALTH SUMMARY + RISK
  // ============================================================

  Widget _buildHealthAndRiskSection() {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        if (constraints.maxWidth <
            800) {
          return Column(
            children: [
              _buildHealthSummary(),

              const SizedBox(
                height: 20,
              ),

              _buildRiskCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Expanded(
              flex: 6,
              child:
              _buildHealthSummary(),
            ),

            const SizedBox(width: 20),

            Expanded(
              flex: 4,
              child:
              _buildRiskCard(),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HEALTH SUMMARY
  // ============================================================

  Widget _buildHealthSummary() {
    return Container(
      padding:
      const EdgeInsets.all(18),

      decoration:
      _mainCardDecoration(),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          const Text(
            "My Health Summary",

            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF6433D5),
            ),
          ),

          const SizedBox(height: 17),

          LayoutBuilder(
            builder: (
                context,
                constraints,
                ) {
              int crossAxisCount = 3;

              if (constraints.maxWidth <
                  500) {
                crossAxisCount = 2;
              }

              return GridView.count(
                crossAxisCount:
                crossAxisCount,

                shrinkWrap: true,

                physics:
                const NeverScrollableScrollPhysics(),

                crossAxisSpacing: 12,
                mainAxisSpacing: 12,

                childAspectRatio: 1.25,

                children: [
                  _healthMetric(
                    "Blood Pressure",
                    _displayValue(
                      _bloodPressure,
                    ),
                    "mmHg",
                    Colors.black87,
                  ),

                  _healthMetric(
                    "Blood Sugar",
                    _displayValue(
                      _bloodSugar,
                    ),
                    "mg/dL",
                    const Color(
                      0xFF6236D5,
                    ),
                  ),

                  _healthMetric(
                    "Heart Rate",
                    _displayValue(
                      _heartRate,
                    ),
                    "bpm",
                    const Color(
                      0xFFFF3340,
                    ),
                  ),

                  _healthMetric(
                    "SpO₂",
                    _displayValue(_spo2),
                    _hasValue(_spo2)
                        ? "%"
                        : "",
                    const Color(
                      0xFF159653,
                    ),
                  ),

                  _healthMetric(
                    "Temperature",
                    _displayValue(
                      _temperature,
                    ),
                    "°F",
                    const Color(
                      0xFF159653,
                    ),
                  ),

                  _healthMetric(
                    "Weight",
                    _displayValue(_weight),
                    "kg",
                    const Color(
                      0xFF27375D,
                    ),
                  ),

                  _healthMetric(
                    "BMI",
                    _displayValue(_bmi),
                    "BMI",
                    const Color(
                      0xFF159653,
                    ),
                  ),

                  _healthMetric(
                    "Last Checkup",
                    _displayValue(
                      _lastCheckup,
                    ),
                    "",
                    const Color(
                      0xFF252332,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEALTH METRIC
  // ============================================================

  Widget _healthMetric(
      String title,
      String value,
      String unit,
      Color valueColor,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(10),

        border: Border.all(
          color:
          const Color(0xFFE9E4F2),
        ),
      ),

      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [
          Text(
            title,

            textAlign:
            TextAlign.center,

            maxLines: 2,

            overflow:
            TextOverflow.ellipsis,

            style:
            const TextStyle(
              fontSize: 11,
              color:
              Color(0xFF777384),
            ),
          ),

          const SizedBox(height: 8),

          Flexible(
            child: Text(
              value,

              textAlign:
              TextAlign.center,

              maxLines: 2,

              overflow:
              TextOverflow.ellipsis,

              style: TextStyle(
                fontSize:
                value ==
                    "Not available"
                    ? 14
                    : 18,

                fontWeight:
                FontWeight.w700,

                color: valueColor,
              ),
            ),
          ),

          if (unit.isNotEmpty) ...[
            const SizedBox(height: 4),

            Text(
              unit,

              textAlign:
              TextAlign.center,

              maxLines: 1,

              overflow:
              TextOverflow.ellipsis,

              style: TextStyle(
                fontSize: 11,

                color:
                valueColor ==
                    Colors.black87
                    ? const Color(
                  0xFF777384,
                )
                    : valueColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // RISK CARD
  // ============================================================

  Widget _buildRiskCard() {
    return Container(
      padding:
      const EdgeInsets.all(20),

      decoration:
      _mainCardDecoration(),

      child: Column(
        children: [
          const Align(
            alignment:
            Alignment.centerLeft,

            child: Text(
              "Risk Prediction (Last Assessment)",

              style: TextStyle(
                fontSize: 15,
                color:
                Color(0xFF5C586C),
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            "Not available",

            style: TextStyle(
              fontSize: 23,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF777384),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 160,
            width: 250,

            child: CustomPaint(
              painter:
              RiskGaugePainter(
                progress: 0.0,
              ),

              child:
              const Center(
                child: Padding(
                  padding:
                  EdgeInsets.only(
                    top: 45,
                  ),

                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      Text(
                        "--",

                        style:
                        TextStyle(
                          fontSize: 29,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(
                            0xFF202033,
                          ),
                        ),
                      ),

                      Text(
                        "Risk Score",

                        style:
                        TextStyle(
                          fontSize: 12,
                          color:
                          Color(
                            0xFF777384,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "No health risk assessment is available yet.\n"
                "Complete your health profile to get started.",

            textAlign:
            TextAlign.center,

            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color:
              Color(0xFF777384),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width:
            double.infinity,

            height: 46,

            child:
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },

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
                    8,
                  ),
                ),
              ),

              child:
              const Text(
                "Complete Health Profile",

                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREDICTIONS + APPOINTMENTS
  // ============================================================

  Widget _buildPredictionsAndAppointments() {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        if (constraints.maxWidth <
            800) {
          return Column(
            children: [
              _buildRecentPredictions(),

              const SizedBox(
                height: 20,
              ),

              _buildUpcomingAppointments(),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Expanded(
              child:
              _buildRecentPredictions(),
            ),

            const SizedBox(width: 20),

            Expanded(
              child:
              _buildUpcomingAppointments(),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // RECENT PREDICTIONS
  // ============================================================

  Widget _buildRecentPredictions() {
    return Container(
      padding:
      const EdgeInsets.all(18),

      decoration:
      _mainCardDecoration(),

      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Recent Predictions",

                  style: TextStyle(
                    color:
                    Color(0xFF6335D6),
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },

                child:
                const Text(
                  "View All",

                  style: TextStyle(
                    color:
                    Color(0xFF6335D6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          _predictionRow(
            "No predictions yet",
            "Not available",
            "--",
            const Color(
              0xFF777384,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREDICTION ROW
  // ============================================================

  Widget _predictionRow(
      String date,
      String risk,
      String percentage,
      Color percentageColor,
      ) {
    return Container(
      constraints:
      const BoxConstraints(
        minHeight: 48,
      ),

      padding:
      const EdgeInsets.symmetric(
        vertical: 8,
      ),

      decoration:
      const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
            Color(0xFFEDE9F3),
          ),
        ),
      ),

      child: Row(
        children: [
          Expanded(
            child: Text(
              date,

              maxLines: 2,

              overflow:
              TextOverflow.ellipsis,

              style:
              const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF777384),
              ),
            ),
          ),

          Expanded(
            child: Text(
              risk,

              textAlign:
              TextAlign.center,

              maxLines: 2,

              overflow:
              TextOverflow.ellipsis,

              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFF777384),
              ),
            ),
          ),

          SizedBox(
            width: 50,

            child: Text(
              percentage,

              textAlign:
              TextAlign.right,

              style: TextStyle(
                fontSize: 12,
                color:
                percentageColor,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPCOMING APPOINTMENTS
  // ============================================================

  Widget _buildUpcomingAppointments() {
    return Container(
      padding:
      const EdgeInsets.all(18),

      decoration:
      _mainCardDecoration(),

      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Upcoming Appointments",

                  style: TextStyle(
                    color:
                    Color(0xFF6335D6),
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 4;
                  });
                },

                child:
                const Text(
                  "View All",

                  style: TextStyle(
                    color:
                    Color(0xFF6335D6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding:
            const EdgeInsets.all(16),

            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFFAF7FF,
              ),

              borderRadius:
              BorderRadius.circular(
                10,
              ),

              border:
              Border.all(
                color:
                const Color(
                  0xFFEDE5FA,
                ),
              ),
            ),

            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,

                  decoration:
                  const BoxDecoration(
                    color:
                    Color(0xFFEFE7FF),
                    shape:
                    BoxShape.circle,
                  ),

                  child:
                  const Icon(
                    Icons.calendar_month,
                    color:
                    Color(0xFF6335D6),
                    size: 23,
                  ),
                ),

                const SizedBox(width: 14),

                const Expanded(
                  child: Text(
                    "No upcoming appointments",

                    maxLines: 2,

                    overflow:
                    TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Color(0xFF777384),
                    ),
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
  // HEALTH TIP
  // ============================================================

  Widget _buildHealthTip() {
    return Container(
      constraints:
      const BoxConstraints(
        minHeight: 115,
      ),

      padding:
      const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF8F1FF),

        borderRadius:
        BorderRadius.circular(12),

        border: Border.all(
          color:
          const Color(0xFFE7D9FA),
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

            child:
            const Icon(
              Icons.lightbulb_outline,
              color:
              Color(0xFF7042D9),
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  "Health Tip of the Day",

                  style: TextStyle(
                    color:
                    Color(0xFF6335D6),
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                SizedBox(height: 9),

                Text(
                  "Drink plenty of water and eat a balanced diet to stay healthy.",

                  maxLines: 3,

                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    color:
                    Color(0xFF5F5A6D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            height: 70,
            width: 76,

            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF0E5FF),

              borderRadius:
              BorderRadius.circular(
                40,
              ),
            ),

            child:
            const Icon(
              Icons.medical_services_outlined,
              color:
              Color(0xFF7042D9),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _mainCardDecoration() {
    return BoxDecoration(
      color: Colors.white,

      borderRadius:
      BorderRadius.circular(12),

      border: Border.all(
        color:
        const Color(0xFFE8E2F2),
      ),

      boxShadow: [
        BoxShadow(
          color: Colors.black
              .withOpacity(0.025),

          blurRadius: 12,

          offset:
          const Offset(0, 4),
        ),
      ],
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  Widget _buildComingSoonScreen({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      color:
      const Color(0xFFFDFBFF),

      child: Center(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(
            30,
          ),

          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [
              Container(
                height: 90,
                width: 90,

                decoration:
                const BoxDecoration(
                  color:
                  Color(0xFFEFE7FF),
                  shape:
                  BoxShape.circle,
                ),

                child: Icon(
                  icon,

                  size: 45,

                  color:
                  const Color(
                    0xFF6335D6,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Text(
                title,

                textAlign:
                TextAlign.center,

                style:
                const TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF242044),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                subtitle,

                textAlign:
                TextAlign.center,

                style:
                const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                  Color(0xFF777384),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),

                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF0EBFF,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                child:
                const Text(
                  "Coming Soon",

                  style:
                  TextStyle(
                    color:
                    Color(0xFF6335D6),
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccessMessage(
      String message,
      ) {
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

                style:
                const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        duration:
        const Duration(
          seconds: 3,
        ),
      ),
    );
  }

  // ============================================================
  // NORMAL MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,

          style:
          const TextStyle(
            fontSize: 14,
          ),
        ),

        duration:
        const Duration(
          seconds: 3,
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Logout",

            style: TextStyle(
              fontSize: 21,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          content:
          const Text(
            "Are you sure you want to logout?",

            style: TextStyle(
              fontSize: 15,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },

              child:
              const Text(
                "Cancel",

                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),

            ElevatedButton(
              onPressed:
                  () async {
                Navigator.pop(
                  context,
                );

                await FirebaseAuth
                    .instance
                    .signOut();

                if (!mounted) {
                  return;
                }

                Navigator
                    .pushAndRemoveUntil(
                  context,

                  MaterialPageRoute(
                    builder:
                        (context) =>
                    const LoginScreen(),
                  ),

                      (route) => false,
                );
              },

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF6335D6,
                ),
              ),

              child:
              const Text(
                "Logout",

                style:
                TextStyle(
                  color:
                  Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ================================================================
// RISK GAUGE CUSTOM PAINTER
// ================================================================

class RiskGaugePainter
    extends CustomPainter {
  final double progress;

  RiskGaugePainter({
    required this.progress,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = Offset(
      size.width / 2,
      size.height * 0.82,
    );

    final radius =
        size.width * 0.36;

    final backgroundPaint =
    Paint()
      ..color =
      const Color(
        0xFFE9E9EE,
      )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap =
          StrokeCap.round;

    final progressPaint =
    Paint()
      ..color =
      const Color(
        0xFFFF9000,
      )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap =
          StrokeCap.round;

    const startAngle = 3.45;
    const sweepAngle = 3.82;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),

      startAngle,

      sweepAngle,

      false,

      backgroundPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),

        startAngle,

        sweepAngle * progress,

        false,

        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant RiskGaugePainter
      oldDelegate,
      ) {
    return oldDelegate.progress !=
        progress;
  }
}