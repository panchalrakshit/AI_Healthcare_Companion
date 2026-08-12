import 'package:flutter/material.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),

      // ================================================================
      // APP BAR
      // ================================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF7FF),
        elevation: 0,

        leading: IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.menu,
            color: Color(0xFF202020),
          ),
        ),

        title: const Text(
          "Healthcare Companion",
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFF202020),
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF202020),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ================================================================
      // BODY
      // ================================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ==========================================================
              // GREETING
              // ==========================================================

              const Text(
                "Good Morning, Rakshit 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Here's your health overview",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF888888),
                ),
              ),

              const SizedBox(height: 25),

              // ==========================================================
              // HEALTH STATUS CARD
              // ==========================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: const Color(0xFFF1E9F8),
                  borderRadius: BorderRadius.circular(22),
                ),

                child: Row(
                  children: [

                    Container(
                      height: 58,
                      width: 58,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFF7352B5),
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 18),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Health Status",
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF777777),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "You're doing great!",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202020),
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "Last updated today",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================================
              // UPCOMING APPOINTMENT
              // ==========================================================

              const Text(
                "Upcoming Appointment",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(
                    color: const Color(0xFFE5E0E8),
                  ),
                ),

                child: Row(
                  children: [

                    // Doctor icon
                    Container(
                      height: 55,
                      width: 55,

                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E9F8),
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Color(0xFF7352B5),
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 15),

                    // Doctor information
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Dr. Sharma",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202020),
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "Cardiologist",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF888888),
                            ),
                          ),

                          SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: Color(0xFF7352B5),
                              ),

                              SizedBox(width: 6),

                              Text(
                                "Tomorrow • 10:30 AM",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF999999),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================================
              // QUICK ACCESS
              // ==========================================================

              const Text(
                "Quick Access",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
              ),

              const SizedBox(height: 15),

              // First row
              Row(
                children: [

                  Expanded(
                    child: _quickAccessCard(
                      icon: Icons.folder_open_outlined,
                      title: "Medical Records",
                      onTap: () {},
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: _quickAccessCard(
                      icon: Icons.calendar_month_outlined,
                      title: "Appointments",
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Second row
              Row(
                children: [

                  Expanded(
                    child: _quickAccessCard(
                      icon: Icons.medication_outlined,
                      title: "Medicines",
                      onTap: () {},
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: _quickAccessCard(
                      icon: Icons.smart_toy_outlined,
                      title: "AI Health",
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ==========================================================
              // RECENT RECORD
              // ==========================================================

              const Text(
                "Recent Medical Record",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(
                    color: const Color(0xFFE5E0E8),
                  ),
                ),

                child: Row(
                  children: [

                    Container(
                      height: 50,
                      width: 50,

                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E9F8),
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF7352B5),
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [
                          Text(
                            "General Health Checkup",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202020),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "Dr. Sharma • 10 Aug 2026",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF999999),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ================================================================
      // BOTTOM NAVIGATION
      // ================================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        onTap: _onBottomNavTapped,

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,

        selectedItemColor: const Color(0xFF7352B5),

        unselectedItemColor: const Color(0xFF999999),

        selectedFontSize: 12,

        unselectedFontSize: 12,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_outlined),
            activeIcon: Icon(Icons.folder),
            label: "Records",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: "Appointments",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK ACCESS CARD
  // ================================================================

  Widget _quickAccessCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: onTap,

      child: Container(
        height: 135,
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: const Color(0xFFE5E0E8),
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Container(
              height: 45,
              width: 45,

              decoration: BoxDecoration(
                color: const Color(0xFFF1E9F8),
                borderRadius: BorderRadius.circular(14),
              ),

              child: Icon(
                icon,
                color: const Color(0xFF7352B5),
                size: 24,
              ),
            ),

            const Spacer(),

            Text(
              title,

              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF202020),
              ),
            ),
          ],
        ),
      ),
    );
  }
}