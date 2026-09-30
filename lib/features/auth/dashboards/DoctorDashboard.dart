import 'dart:math' as math;
import 'package:ai_healthcompanion_using_flutter/features/auth/login/login_screen.dart' show LoginScreen;
import 'package:flutter/material.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int selectedMenu = 0;

  final List<String> menuItems = [
    "Dashboard",
    "My Patients",
    "Patient Assessment",
    "Predictions",
    "Appointments",
    "Notifications",
    "Reports",
    "Profile",
    "Logout",
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.assignment_outlined,
    Icons.analytics_outlined,
    Icons.calendar_month_outlined,
    Icons.notifications_none_outlined,
    Icons.description_outlined,
    Icons.person_outline,
    Icons.logout,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 210,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF006B67),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // LOGO
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF006B67),
                  size: 24,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                "Smart Hospital",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 35),

          // MENU
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItem(
                  index,
                  menuItems[index],
                  menuIcons[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      int index,
      String title,
      IconData icon,
      ) {
    final bool selected = selectedMenu == index;

    return GestureDetector(
      onTap: () {
        if (title == "Logout") {
          _showLogoutDialog();
          return;
        }

        setState(() {
          selectedMenu = index;
        });
      },
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? const Color(0xFF006B67)
                  : Colors.white,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selected
                      ? const Color(0xFF006B67)
                      : Colors.white,
                ),
              ),
            ),

            if (title == "Notifications")
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "3",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double dashboardWidth =
        math.max(constraints.maxWidth, 1100);

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: dashboardWidth,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  22,
                  22,
                  35,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 24),

                    _buildStatistics(),

                    const SizedBox(height: 20),

                    _buildMiddleSection(),

                    const SizedBox(height: 20),

                    _buildBottomSection(),

                    const SizedBox(height: 30),

                    _buildNewAssessment(),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFDDEDEA),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            color: Color(0xFF006B67),
            size: 32,
          ),
        ),

        const SizedBox(width: 13),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Welcome back,",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 3),

            Text(
              "Dr. Rahul Mehta",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF202020),
              ),
            ),
          ],
        ),

        const Spacer(),

        // SEARCH
        Container(
          width: 240,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: const Color(0xFFE0EAEA),
            ),
          ),
          child: const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Colors.grey,
              ),
              hintText: "Search patient...",
              hintStyle: TextStyle(
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 13,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        _buildHeaderIcon(
          Icons.notifications_none,
          badge: "3",
        ),

        const SizedBox(width: 10),

        _buildHeaderIcon(
          Icons.calendar_today_outlined,
        ),

        const SizedBox(width: 14),

        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE0EAEA),
            ),
          ),
          child: const Icon(
            Icons.person,
            size: 25,
            color: Color(0xFF006B67),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(
      IconData icon, {
        String? badge,
      }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: const Color(0xFFE0EAEA),
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF006B67),
          ),
        ),

        if (badge != null)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              width: 19,
              height: 19,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "My Patients",
            value: "120",
            subtitle: "Total Assigned",
            icon: Icons.people_outline,
            iconColor: const Color(0xFF008C82),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _statCard(
            title: "High-Risk Patients",
            value: "16",
            subtitle: "Needs Attention",
            icon: Icons.favorite_border,
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _statCard(
            title: "Today's Appointments",
            value: "18",
            subtitle: "Scheduled",
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF7650C8),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _statCard(
            title: "Critical Alerts",
            value: "5",
            subtitle: "New Alerts",
            icon: Icons.notifications_none,
            iconColor: Colors.orange,
            titleColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color? titleColor,
  }) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2EAEA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: titleColor ??
                        const Color(0xFF007B73),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202020),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MIDDLE SECTION
  // ============================================================

  Widget _buildMiddleSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildRiskOverview(),
        ),

        const SizedBox(width: 18),

        Expanded(
          child: _buildRecentAssessments(),
        ),
      ],
    );
  }

  // ============================================================
  // RISK OVERVIEW
  // ============================================================

  Widget _buildRiskOverview() {
    return _panel(
      title: "Risk Overview",
      child: Row(
        children: [
          SizedBox(
            width: 175,
            height: 175,
            child: CustomPaint(
              painter: RiskChartPainter(),
            ),
          ),

          const SizedBox(width: 25),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _riskLegend(
                Colors.redAccent,
                "High Risk",
                "16 (13.3%)",
              ),

              const SizedBox(height: 22),

              _riskLegend(
                Colors.orange,
                "Medium Risk",
                "62 (51.7%)",
              ),

              const SizedBox(height: 22),

              _riskLegend(
                const Color(0xFFFFC13B),
                "Low Risk",
                "42 (35.0%)",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _riskLegend(
      Color color,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 9),

        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECENT ASSESSMENTS
  // ============================================================

  Widget _buildRecentAssessments() {
    final patients = [
      ["P1001", "Raj Sharma", "High", "92%", "10:30 AM"],
      ["P1002", "Anita Verma", "Medium", "68%", "11:15 AM"],
      ["P1003", "Mohan Patel", "High", "86%", "12:00 PM"],
      ["P1004", "Suresh Yadav", "Medium", "74%", "01:10 PM"],
      ["P1005", "Neha Singh", "Medium", "64%", "02:20 PM"],
    ];

    return _panel(
      title: "Recent Patient Assessments",
      child: Column(
        children: [
          _assessmentHeader(),

          const SizedBox(height: 10),

          ...patients.map(
                (patient) => _assessmentRow(patient),
          ),
        ],
      ),
    );
  }

  Widget _assessmentHeader() {
    return Row(
      children: const [
        SizedBox(
          width: 65,
          child: Text(
            "ID",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          child: Text(
            "Patient",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(
          width: 75,
          child: Text(
            "Risk",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(
          width: 60,
          child: Text(
            "Score",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(
          width: 75,
          child: Text(
            "Time",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _assessmentRow(List<String> data) {
    final bool highRisk = data[2] == "High";

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF0F0F0),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(
              data[0],
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),

          Expanded(
            child: Text(
              data[1],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          SizedBox(
            width: 75,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 6,
              ),
              decoration: BoxDecoration(
                color: highRisk
                    ? Colors.red.withOpacity(0.08)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                data[2],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: highRisk
                      ? Colors.redAccent
                      : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(
            width: 60,
            child: Text(
              data[3],
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),

          SizedBox(
            width: 75,
            child: Text(
              data[4],
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM SECTION
  // ============================================================

  Widget _buildBottomSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildAppointments(),
        ),

        const SizedBox(width: 18),

        Expanded(
          child: _buildAlerts(),
        ),
      ],
    );
  }

  // ============================================================
  // APPOINTMENTS
  // ============================================================

  Widget _buildAppointments() {
    final appointments = [
      ["10:30 AM", "Raj Sharma (P1001)", "Follow Up"],
      ["11:15 AM", "Anita Verma (P1002)", "Consultation"],
      ["12:00 PM", "Mohan Patel (P1003)", "Review"],
      ["01:10 PM", "Suresh Yadav (P1004)", "Checkup"],
      ["02:20 PM", "Neha Singh (P1005)", "Consultation"],
    ];

    return _panel(
      title: "Upcoming Appointments",
      action: "View All",
      onAction: () {
        _showMessage(
          "Opening all appointments...",
        );
      },
      child: Column(
        children: appointments.map(
              (item) {
            return Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFF0F0F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      item[0],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      item[1],
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),

                  Text(
                    item[2],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // ALERTS
  // ============================================================

  Widget _buildAlerts() {
    final alerts = [
      [
        "P1001 Raj Sharma",
        "High risk of Pneumonia detected",
        "10:30 AM",
        true,
      ],
      [
        "P1003 Mohan Patel",
        "High blood sugar level detected",
        "9:45 AM",
        true,
      ],
      [
        "P1006 Karuna Joshi",
        "Low SpO2 level detected",
        "9:20 AM",
        false,
      ],
    ];

    return _panel(
      title: "Recent Alerts",
      action: "View All",
      onAction: () {
        _showMessage(
          "Opening all alerts...",
        );
      },
      child: Column(
        children: alerts.map(
              (alert) {
            final bool danger = alert[3] as bool;

            return Container(
              height: 65,
              margin: const EdgeInsets.only(
                bottom: 9,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFECECEC),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: danger
                          ? Colors.red.withOpacity(0.08)
                          : Colors.green.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      danger
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: danger
                          ? Colors.redAccent
                          : Colors.green,
                      size: 19,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert[0] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          alert[1] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    alert[2] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // NEW ASSESSMENT
  // ============================================================

  Widget _buildNewAssessment() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD9EEEB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F4F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_add,
              color: Color(0xFF008C82),
              size: 25,
            ),
          ),

          const SizedBox(width: 15),

          Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: const [
              Text(
                "Start New Assessment",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 5),

              Text(
                "Assess a patient and get AI-powered prediction",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const Spacer(),

          ElevatedButton(
            onPressed: () {
              _showMessage(
                "New Patient Assessment selected",
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF008C82),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(7),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  "New Assessment",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(width: 8),

                Icon(
                  Icons.arrow_forward,
                  size: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMON PANEL
  // ============================================================

  Widget _panel({
    required String title,
    required Widget child,
    String? action,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2EAEA),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202020),
                ),
              ),

              const Spacer(),

              if (action != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF008C82),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        duration: const Duration(seconds: 2),
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
              fontSize: 20,
            ),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {

              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginScreen()));
                _showMessage(
                  "Logout selected",
                );
              },
              child: const Text(
                "Logout",
                style: TextStyle(
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

// ============================================================
// RISK DONUT CHART
// ============================================================

class RiskChartPainter extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(size.width, size.height) / 2 - 12;

    const strokeWidth = 27.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // HIGH RISK
    paint.color = Colors.redAccent;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      math.pi * 0.27,
      false,
      paint,
    );

    // MEDIUM RISK
    paint.color = Colors.orange;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2 + math.pi * 0.27,
      math.pi * 0.55,
      false,
      paint,
    );

    // LOW RISK
    paint.color = const Color(0xFFFFC13B);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2 + math.pi * 0.82,
      math.pi * 0.18,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}