import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  // ============================================================
  // VARIABLES
  // ============================================================

  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = "";

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // DOCTORS STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _doctorsStream() {
    return FirebaseFirestore.instance
        .collection("doctors")
        .snapshots();
  }

  // ============================================================
  // APPOINTMENTS STREAM
  // ============================================================

  // IMPORTANT:
  // We intentionally DO NOT use orderBy() here.
  //
  // Using:
  // where(patientId) + orderBy(appointmentDate)
  //
  // may require a Firestore composite index.
  //
  // We fetch the patient's appointments and sort them locally
  // inside the StreamBuilder instead.

  Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentsStream() {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Stream.empty();
    }

    debugPrint(
      "Loading appointments for UID: ${currentUser.uid}",
    );

    return FirebaseFirestore.instance
        .collection("appointments")
        .where(
      "patientId",
      isEqualTo: currentUser.uid,
    )
        .snapshots();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

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
          "Appointments",
          style: TextStyle(
            color: Color(0xFF242044),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              _buildSearchBar(),

              const SizedBox(height: 25),

              _buildAppointmentsSection(),

              const SizedBox(height: 30),

              _buildDoctorsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7352B5),
            Color(0xFF5B3BA5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7352B5).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            height: 55,
            width: 55,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Book an Appointment",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  "Find a doctor and schedule your visit.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
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
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,

      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },

      decoration: InputDecoration(
        hintText: "Search doctor or specialization",

        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF7352B5),
        ),

        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
          icon: const Icon(
            Icons.clear_rounded,
          ),
          onPressed: () {
            _searchController.clear();

            setState(() {
              _searchQuery = "";
            });
          },
        )
            : null,

        filled: true,

        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE3DFEA),
          ),
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
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APPOINTMENTS SECTION
  // ============================================================

  Widget _buildAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Appointments",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF252332),
          ),
        ),

        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _appointmentsStream(),

          builder: (context, snapshot) {
            // ==================================================
            // LOADING
            // ==================================================

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF6335D6),
                  ),
                ),
              );
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (snapshot.hasError) {
              debugPrint(
                "========================================",
              );

              debugPrint(
                "APPOINTMENTS FIRESTORE ERROR:",
              );

              debugPrint(
                snapshot.error.toString(),
              );

              debugPrint(
                "========================================",
              );

              return _buildAppointmentError(
                snapshot.error.toString(),
              );
            }

            // ==================================================
            // GET DOCUMENTS
            // ==================================================

            final documents =
                snapshot.data?.docs.toList() ?? [];

            debugPrint(
              "Appointments found: ${documents.length}",
            );

            // ==================================================
            // SORT LOCALLY
            // ==================================================

            documents.sort((a, b) {
              final aData = a.data();
              final bData = b.data();

              final dynamic aDate =
              aData["appointmentDate"];

              final dynamic bDate =
              bData["appointmentDate"];

              if (aDate is Timestamp &&
                  bDate is Timestamp) {
                return aDate.compareTo(bDate);
              }

              if (aDate is Timestamp) {
                return -1;
              }

              if (bDate is Timestamp) {
                return 1;
              }

              return 0;
            });

            // ==================================================
            // EMPTY
            // ==================================================

            if (documents.isEmpty) {
              return _buildNoAppointments();
            }

            // ==================================================
            // DISPLAY APPOINTMENTS
            // ==================================================

            return Column(
              children: documents.map((document) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _buildAppointmentCard(
                    document,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // NO APPOINTMENTS
  // ============================================================

  Widget _buildNoAppointments() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: _cardDecoration(),

      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,

            decoration: const BoxDecoration(
              color: Color(0xFFF0EBFF),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF6335D6),
              size: 28,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "No appointments yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF252332),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "Book an appointment with a doctor below.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF777384),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPOINTMENT ERROR
  // ============================================================

  Widget _buildAppointmentError(String error) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: _cardDecoration(),

      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 40,
          ),

          const SizedBox(height: 10),

          const Text(
            "Unable to load appointments.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Please check your Firestore configuration.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF777384),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPOINTMENT CARD
  // ============================================================

  Widget _buildAppointmentCard(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final Map<String, dynamic> data =
    document.data();

    final String doctorName =
        data["doctorName"]?.toString() ??
            "Doctor";

    final String specialization =
        data["specialization"]?.toString() ??
            "Medical Specialist";

    final String reason =
        data["reason"]?.toString() ?? "";

    final String status =
        data["status"]?.toString() ??
            "pending";

    final Timestamp? appointmentDate =
    data["appointmentDate"] is Timestamp
        ? data["appointmentDate"] as Timestamp
        : null;

    final String time =
        data["appointmentTime"]?.toString() ??
            "";

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: _cardDecoration(),

      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Container(
                height: 50,
                width: 50,

                decoration: const BoxDecoration(
                  color: Color(0xFFF0EBFF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF6335D6),
                  size: 27,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      doctorName,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w700,
                        color: Color(0xFF252332),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      specialization,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777384),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(
            height: 1,
            color: Color(0xFFEDE9F3),
          ),

          const SizedBox(height: 13),

          if (appointmentDate != null)
            _appointmentDetailRow(
              Icons.calendar_today_outlined,
              "Date",
              _formatDate(appointmentDate),
            ),

          if (time.isNotEmpty)
            _appointmentDetailRow(
              Icons.access_time_rounded,
              "Time",
              time,
            ),

          if (reason.isNotEmpty)
            _appointmentDetailRow(
              Icons.notes_outlined,
              "Reason",
              reason,
            ),

          if (status.toLowerCase() != "cancelled")
            const SizedBox(height: 8),

          if (status.toLowerCase() != "cancelled")
            SizedBox(
              width: double.infinity,
              height: 42,

              child: OutlinedButton(
                onPressed: () {
                  _confirmCancelAppointment(
                    document.id,
                    doctorName,
                  );
                },

                style: OutlinedButton.styleFrom(
                  foregroundColor:
                  const Color(0xFFD83A45),

                  side: const BorderSide(
                    color: Color(0xFFD83A45),
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(9),
                  ),
                ),

                child: const Text(
                  "Cancel Appointment",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final String normalized =
    status.toLowerCase();

    Color background;
    Color foreground;

    if (normalized == "confirmed") {
      background = const Color(0xFFE5F6EB);
      foreground = const Color(0xFF168A62);
    } else if (normalized == "cancelled") {
      background = const Color(0xFFFFE8EA);
      foreground = const Color(0xFFD83A45);
    } else if (normalized == "completed") {
      background = const Color(0xFFE7F0FF);
      foreground = const Color(0xFF438EF5);
    } else {
      background = const Color(0xFFFFF1DF);
      foreground = const Color(0xFFDD7900);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // APPOINTMENT DETAIL ROW
  // ============================================================

  Widget _appointmentDetailRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: const Color(0xFF7352B5),
          ),

          const SizedBox(width: 9),

          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF777384),
            ),
          ),

          Expanded(
            child: Text(
              value,
              overflow:
              TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF292637),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCTORS SECTION
  // ============================================================

  Widget _buildDoctorsSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        const Text(
          "Available Doctors",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF252332),
          ),
        ),

        const SizedBox(height: 14),

        StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _doctorsStream(),

          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: CircularProgressIndicator(
                    color: Color(0xFF6335D6),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              debugPrint(
                "Doctors error: ${snapshot.error}",
              );

              return _buildDoctorsError();
            }

            final documents =
                snapshot.data?.docs ?? [];

            final filteredDoctors =
            documents.where((document) {
              final data = document.data();

              final String name =
                  data["name"]
                      ?.toString()
                      .toLowerCase() ??
                      "";

              final String specialization =
                  data["specialization"]
                      ?.toString()
                      .toLowerCase() ??
                      "";

              return name.contains(
                _searchQuery,
              ) ||
                  specialization.contains(
                    _searchQuery,
                  );
            }).toList();

            if (filteredDoctors.isEmpty) {
              return _buildNoDoctors();
            }

            return Column(
              children:
              filteredDoctors.map(
                    (document) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 14,
                    ),

                    child:
                    _buildDoctorCard(
                      document,
                    ),
                  );
                },
              ).toList(),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // DOCTOR CARD
  // ============================================================

  Widget _buildDoctorCard(
      QueryDocumentSnapshot<Map<String, dynamic>>
      document,
      ) {
    final Map<String, dynamic> data =
    document.data();

    final String name =
        data["name"]?.toString() ??
            "Doctor";

    final String specialization =
        data["specialization"]?.toString() ??
            "Medical Specialist";

    final String experience =
        data["experience"]?.toString() ?? "";

    final String qualification =
        data["qualification"]?.toString() ?? "";

    final String hospital =
        data["hospital"]?.toString() ??
            data["hospitalName"]?.toString() ??
            "";

    final String availability =
        data["availability"]?.toString() ??
            "Available";

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Container(
                height: 62,
                width: 62,

                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7352B5),
                      Color(0xFF5B3BA5),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w700,
                        color: Color(0xFF252332),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      specialization,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6335D6),
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    if (qualification
                        .isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Text(
                        qualification,
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
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (experience.isNotEmpty ||
              hospital.isNotEmpty)
            Row(
              children: [
                if (experience.isNotEmpty)
                  Expanded(
                    child:
                    _doctorInfoItem(
                      Icons.work_outline,
                      "$experience years",
                    ),
                  ),

                if (hospital.isNotEmpty)
                  Expanded(
                    child:
                    _doctorInfoItem(
                      Icons
                          .local_hospital_outlined,
                      hospital,
                    ),
                  ),
              ],
            ),

          if (experience.isNotEmpty ||
              hospital.isNotEmpty)
            const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 10,
                      color: Color(0xFF168A62),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        availability,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,

                        style:
                        const TextStyle(
                          fontSize: 12,
                          color:
                          Color(0xFF168A62),
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              ElevatedButton(
                onPressed: () {
                  _showBookAppointmentDialog(
                    doctorId: document.id,
                    doctorName: name,
                    specialization:
                    specialization,
                  );
                },

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF6335D6),

                  foregroundColor:
                  Colors.white,

                  elevation: 0,

                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(9),
                  ),
                ),

                child: const Text(
                  "Book Appointment",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCTOR INFO ITEM
  // ============================================================

  Widget _doctorInfoItem(
      IconData icon,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF7352B5),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow:
            TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF777384),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NO DOCTORS
  // ============================================================

  Widget _buildNoDoctors() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(25),

      decoration: _cardDecoration(),

      child: const Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 50,
            color: Color(0xFF8B8499),
          ),

          SizedBox(height: 12),

          Text(
            "No doctors found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 5),

          Text(
            "Try searching with a different name or specialization.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF777384),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCTORS ERROR
  // ============================================================

  Widget _buildDoctorsError() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: _cardDecoration(),

      child: const Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 45,
          ),

          SizedBox(height: 12),

          Text(
            "Unable to load doctors.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 5),

          Text(
            "Please check your Firestore configuration.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF777384),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOK APPOINTMENT DIALOG
  // ============================================================

  void _showBookAppointmentDialog({
    required String doctorId,
    required String doctorName,
    required String specialization,
  }) {
    DateTime selectedDate =
    DateTime.now().add(
      const Duration(days: 1),
    );

    String selectedTime = "10:00 AM";

    final TextEditingController reasonController =
    TextEditingController();

    bool isSaving = false;

    final List<String> availableTimes = [
      "09:00 AM",
      "09:30 AM",
      "10:00 AM",
      "10:30 AM",
      "11:00 AM",
      "11:30 AM",
      "12:00 PM",
      "02:00 PM",
      "02:30 PM",
      "03:00 PM",
      "03:30 PM",
      "04:00 PM",
      "04:30 PM",
      "05:00 PM",
    ];

    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              title: const Text(
                "Book Appointment",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              content: SizedBox(
                width: 500,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      // DOCTOR
                      Container(
                        width: double.infinity,

                        padding:
                        const EdgeInsets.all(
                          14,
                        ),

                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFF5F1FF,
                          ),

                          borderRadius:
                          BorderRadius
                              .circular(
                            11,
                          ),
                        ),

                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor:
                              Color(
                                0xFFE7DEFF,
                              ),

                              child: Icon(
                                Icons
                                    .person_outline_rounded,
                                color:
                                Color(
                                  0xFF6335D6,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  Text(
                                    doctorName,
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,

                                    style:
                                    const TextStyle(
                                      fontSize:
                                      15,
                                      fontWeight:
                                      FontWeight
                                          .w700,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    specialization,
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,

                                    style:
                                    const TextStyle(
                                      fontSize:
                                      11,
                                      color:
                                      Color(
                                        0xFF777384,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      // DATE
                      const Text(
                        "Appointment Date",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      InkWell(
                        onTap: isSaving
                            ? null
                            : () async {
                          final DateTime?
                          picked =
                          await showDatePicker(
                            context:
                            context,

                            initialDate:
                            selectedDate,

                            firstDate:
                            DateTime
                                .now(),

                            lastDate:
                            DateTime.now()
                                .add(
                              const Duration(
                                days: 90,
                              ),
                            ),
                          );

                          if (picked !=
                              null) {
                            setDialogState(
                                  () {
                                selectedDate =
                                    picked;
                              },
                            );
                          }
                        },

                        child:
                        InputDecorator(
                          decoration:
                          _dialogInputDecoration(
                            Icons
                                .calendar_today_outlined,
                          ),

                          child: Text(
                            _formatDateFromDateTime(
                              selectedDate,
                            ),

                            style:
                            const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      // TIME
                      const Text(
                        "Appointment Time",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      DropdownButtonFormField<
                          String>(
                        value: selectedTime,

                        decoration:
                        _dialogInputDecoration(
                          Icons
                              .access_time_rounded,
                        ),

                        items:
                        availableTimes.map(
                              (time) {
                            return DropdownMenuItem(
                              value: time,
                              child:
                              Text(time),
                            );
                          },
                        ).toList(),

                        onChanged: isSaving
                            ? null
                            : (value) {
                          if (value !=
                              null) {
                            setDialogState(
                                  () {
                                selectedTime =
                                    value;
                              },
                            );
                          }
                        },
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      // REASON
                      const Text(
                        "Reason for Visit",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextField(
                        controller:
                        reasonController,

                        maxLines: 4,

                        enabled: !isSaving,

                        decoration:
                        _dialogInputDecoration(
                          Icons.notes_outlined,
                        ).copyWith(
                          hintText:
                          "Describe the reason for your appointment",
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },

                  child: const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    setDialogState(
                          () {
                        isSaving = true;
                      },
                    );

                    final bool success =
                    await _saveAppointment(
                      doctorId: doctorId,
                      doctorName:
                      doctorName,
                      specialization:
                      specialization,
                      appointmentDate:
                      selectedDate,
                      appointmentTime:
                      selectedTime,
                      reason:
                      reasonController
                          .text
                          .trim(),
                    );

                    if (!mounted) {
                      return;
                    }

                    if (success) {
                      Navigator.pop(
                        dialogContext,
                      );
                    } else {
                      setDialogState(
                            () {
                          isSaving = false;
                        },
                      );
                    }
                  },

                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF6335D6,
                    ),
                    foregroundColor:
                    Colors.white,
                  ),

                  child: isSaving
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
                      : const Text(
                    "Confirm Appointment",
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      reasonController.dispose();
    });
  }

  // ============================================================
  // SAVE APPOINTMENT
  // ============================================================

  Future<bool> _saveAppointment({
    required String doctorId,
    required String doctorName,
    required String specialization,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String reason,
  }) async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        "You are not logged in.",
      );

      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection("appointments")
          .add({
        "patientId": currentUser.uid,

        "patientName":
        currentUser.displayName ??
            "Patient",

        "patientEmail":
        currentUser.email ?? "",

        "doctorId": doctorId,

        "doctorName": doctorName,

        "specialization":
        specialization,

        "appointmentDate":
        Timestamp.fromDate(
          appointmentDate,
        ),

        "appointmentTime":
        appointmentTime,

        "reason": reason,

        "status": "pending",

        "createdAt":
        FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return true;
      }

      _showSuccessMessage(
        "Appointment booked successfully!",
      );

      return true;
    } catch (e) {
      debugPrint(
        "Error saving appointment: $e",
      );

      if (mounted) {
        _showMessage(
          "Unable to book appointment. Please try again.",
        );
      }

      return false;
    }
  }

  // ============================================================
  // CANCEL CONFIRMATION
  // ============================================================

  void _confirmCancelAppointment(
      String appointmentId,
      String doctorName,
      ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Cancel Appointment",
            style: TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          content: Text(
            "Are you sure you want to cancel "
                "your appointment with $doctorName?",

            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                "No",
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await _cancelAppointment(
                  appointmentId,
                );
              },

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFFD83A45,
                ),
                foregroundColor:
                Colors.white,
              ),

              child: const Text(
                "Yes, Cancel",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CANCEL APPOINTMENT
  // ============================================================

  Future<void> _cancelAppointment(
      String appointmentId,
      ) async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        "You are not logged in.",
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("appointments")
          .doc(appointmentId)
          .update({
        "status": "cancelled",
        "cancelledAt":
        FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showSuccessMessage(
        "Appointment cancelled.",
      );
    } catch (e) {
      debugPrint(
        "Error cancelling appointment: $e",
      );

      if (mounted) {
        _showMessage(
          "Unable to cancel appointment.",
        );
      }
    }
  }

  // ============================================================
  // DIALOG INPUT DECORATION
  // ============================================================

  InputDecoration _dialogInputDecoration(
      IconData icon,
      ) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF7352B5),
        size: 20,
      ),

      filled: true,

      fillColor:
      const Color(0xFFFAF9FC),

      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(11),

        borderSide:
        const BorderSide(
          color: Color(0xFFE3DFEA),
        ),
      ),

      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(11),

        borderSide:
        const BorderSide(
          color: Color(0xFFE3DFEA),
        ),
      ),

      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(11),

        borderSide:
        const BorderSide(
          color: Color(0xFF7352B5),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,

      borderRadius:
      BorderRadius.circular(16),

      border: Border.all(
        color: const Color(0xFFE4E0EF),
      ),

      boxShadow: [
        BoxShadow(
          color:
          Colors.black.withOpacity(
            0.025,
          ),

          blurRadius: 12,

          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
      Timestamp timestamp,
      ) {
    return _formatDateFromDateTime(
      timestamp.toDate(),
    );
  }

  String _formatDateFromDateTime(
      DateTime date,
      ) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
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
      ),
    );
  }
}