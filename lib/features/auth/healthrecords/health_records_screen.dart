import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() =>
      _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  // ============================================================
  // VARIABLES
  // ============================================================

  bool _isAddingRecord = false;

  // ============================================================
  // FIRESTORE RECORDS STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _recordsStream() {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    // ----------------------------------------------------------
    // NO LOGGED-IN USER
    // ----------------------------------------------------------

    if (currentUser == null) {
      debugPrint(
        "Health Records: No user is currently logged in.",
      );

      return const Stream.empty();
    }

    // ----------------------------------------------------------
    // IMPORTANT:
    //
    // We intentionally DO NOT use orderBy() here.
    //
    // Using:
    //
    // .where('patientId', isEqualTo: uid)
    // .orderBy('recordDate')
    //
    // can require a Firestore composite index.
    //
    // Instead, we fetch the patient's records and sort them
    // locally in Flutter.
    // ----------------------------------------------------------

    debugPrint(
      "Loading health records for UID: ${currentUser.uid}",
    );

    return FirebaseFirestore.instance
        .collection('healthRecords')
        .where(
      'patientId',
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

      // ========================================================
      // APP BAR
      // ========================================================

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
          "Health Records",

          style: TextStyle(
            color: Color(0xFF242044),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // ADD RECORD BUTTON
      // ========================================================

      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6335D6),
        foregroundColor: Colors.white,

        onPressed: _isAddingRecord
            ? null
            : () {
          _showAddRecordDialog();
        },

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          "Add Record",

          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _recordsStream(),

          builder: (context, snapshot) {
            // ==================================================
            // LOADING
            // ==================================================

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6335D6),
                ),
              );
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (snapshot.hasError) {
              debugPrint(
                "================================================",
              );

              debugPrint(
                "HEALTH RECORDS FIRESTORE ERROR",
              );

              debugPrint(
                snapshot.error.toString(),
              );

              debugPrint(
                "================================================",
              );

              return _buildErrorState(
                snapshot.error.toString(),
              );
            }

            // ==================================================
            // GET RECORDS
            // ==================================================

            final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>> records =
                snapshot.data?.docs.toList() ?? [];

            // ==================================================
            // SORT RECORDS
            // ==================================================
            //
            // Newest records first.
            //
            // This replaces Firestore orderBy().
            // ==================================================

            records.sort(
                  (a, b) {
                final Map<String, dynamic> dataA =
                a.data();

                final Map<String, dynamic> dataB =
                b.data();

                final dynamic rawDateA =
                dataA['recordDate'];

                final dynamic rawDateB =
                dataB['recordDate'];

                final Timestamp? dateA =
                rawDateA is Timestamp
                    ? rawDateA
                    : null;

                final Timestamp? dateB =
                rawDateB is Timestamp
                    ? rawDateB
                    : null;

                // Both dates unavailable
                if (dateA == null && dateB == null) {
                  return 0;
                }

                // A has no date -> put A after B
                if (dateA == null) {
                  return 1;
                }

                // B has no date -> put B after A
                if (dateB == null) {
                  return -1;
                }

                // Newest first
                return dateB.compareTo(dateA);
              },
            );

            // ==================================================
            // EMPTY
            // ==================================================

            if (records.isEmpty) {
              return _buildEmptyState();
            }

            // ==================================================
            // RECORD LIST
            // ==================================================

            return RefreshIndicator(
              color: const Color(0xFF6335D6),

              onRefresh: () async {
                // The StreamBuilder automatically listens to
                // Firestore changes.
                //
                // This small delay allows RefreshIndicator
                // to complete normally.
                await Future.delayed(
                  const Duration(
                    milliseconds: 500,
                  ),
                );
              },

              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),

                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  100,
                ),

                children: [
                  // ------------------------------------------------
                  // HEADER
                  // ------------------------------------------------

                  _buildHeader(
                    records.length,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // RECORDS
                  // ------------------------------------------------

                  ...records.map(
                        (document) {
                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 14,
                        ),

                        child:
                        _buildRecordCard(
                          document,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      int recordCount) {
    return Container(
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

        borderRadius:
        BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
            const Color(0xFF7352B5)
                .withOpacity(0.18),

            blurRadius: 18,

            offset:
            const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,

            decoration: BoxDecoration(
              color:
              Colors.white
                  .withOpacity(0.15),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.folder_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                const Text(
                  "My Health Records",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  "$recordCount "
                      "${recordCount == 1 ? 'record' : 'records'} "
                      "available",

                  style:
                  const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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
  // RECORD CARD
  // ============================================================

  Widget _buildRecordCard(
      QueryDocumentSnapshot<
          Map<String, dynamic>>
      document,
      ) {
    final Map<String, dynamic> data =
    document.data();

    // ----------------------------------------------------------
    // GET DATA SAFELY
    // ----------------------------------------------------------

    final String title =
        data['title']?.toString() ??
            "Untitled Record";

    final String recordType =
        data['recordType']?.toString() ??
            "Medical Record";

    final String doctorName =
        data['doctorName']?.toString() ??
            "";

    final String hospitalName =
        data['hospitalName']?.toString() ??
            "";

    final String description =
        data['description']?.toString() ??
            "";

    final Timestamp? recordDate =
    data['recordDate'] is Timestamp
        ? data['recordDate'] as Timestamp
        : null;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color:
          const Color(0xFFE4E0EF),
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(0.025),

            blurRadius: 12,

            offset:
            const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        children: [
          // ======================================================
          // TOP SECTION
          // ======================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // --------------------------------------------------
              // ICON
              // --------------------------------------------------

              Container(
                height: 48,
                width: 48,

                decoration: BoxDecoration(
                  color:
                  const Color(
                    0xFFF0EBFF,
                  ),

                  borderRadius:
                  BorderRadius
                      .circular(
                    13,
                  ),
                ),

                child: Icon(
                  _getRecordIcon(
                    recordType,
                  ),

                  color:
                  const Color(
                    0xFF6335D6,
                  ),

                  size: 25,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              // --------------------------------------------------
              // TITLE + TYPE
              // --------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    Text(
                      title,

                      maxLines: 2,

                      overflow:
                      TextOverflow
                          .ellipsis,

                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight
                            .w700,
                        color:
                        Color(
                          0xFF252332,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFF0EBFF,
                        ),

                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),

                      child: Text(
                        recordType,

                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF6335D6,
                          ),

                          fontSize: 10,

                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --------------------------------------------------
              // MORE MENU
              // --------------------------------------------------

              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,

                  color:
                  Color(
                    0xFF777384,
                  ),
                ),

                onSelected:
                    (value) {
                  if (value ==
                      'view') {
                    _showRecordDetails(
                      document,
                    );
                  }

                  if (value ==
                      'delete') {
                    _confirmDelete(
                      document.id,
                      title,
                    );
                  }
                },

                itemBuilder:
                    (context) {
                  return const [
                    PopupMenuItem(
                      value: 'view',

                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .visibility_outlined,
                            size: 19,
                          ),

                          SizedBox(
                            width: 10,
                          ),

                          Text(
                            "View",
                          ),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: 'delete',

                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline,
                            size: 19,
                            color:
                            Colors.red,
                          ),

                          SizedBox(
                            width: 10,
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

          // ======================================================
          // DETAILS
          // ======================================================

          if (doctorName.isNotEmpty ||
              hospitalName.isNotEmpty ||
              recordDate != null) ...[
            const SizedBox(
              height: 16,
            ),

            const Divider(
              height: 1,
              color:
              Color(0xFFEDE9F3),
            ),

            const SizedBox(
              height: 14,
            ),

            if (doctorName.isNotEmpty)
              _detailRow(
                Icons.person_outline,
                "Doctor",
                doctorName,
              ),

            if (hospitalName.isNotEmpty)
              _detailRow(
                Icons
                    .local_hospital_outlined,
                "Hospital",
                hospitalName,
              ),

            if (recordDate != null)
              _detailRow(
                Icons
                    .calendar_today_outlined,
                "Date",
                _formatDate(
                  recordDate,
                ),
              ),
          ],

          // ======================================================
          // DESCRIPTION
          // ======================================================

          if (description
              .isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            Align(
              alignment:
              Alignment.centerLeft,

              child: Text(
                description,

                maxLines: 3,

                overflow:
                TextOverflow
                    .ellipsis,

                style:
                const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color:
                  Color(
                    0xFF777384,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // VIEW BUTTON
          // ======================================================

          SizedBox(
            width: double.infinity,
            height: 42,

            child:
            OutlinedButton(
              onPressed: () {
                _showRecordDetails(
                  document,
                );
              },

              style:
              OutlinedButton
                  .styleFrom(
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

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    9,
                  ),
                ),
              ),

              child:
              const Text(
                "View Record",

                style:
                TextStyle(
                  fontSize: 13,
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
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),

      child: Row(
        children: [
          Icon(
            icon,

            size: 17,

            color:
            const Color(
              0xFF7352B5,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Text(
            "$label: ",

            style:
            const TextStyle(
              fontSize: 12,
              color:
              Color(
                0xFF777384,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,

              overflow:
              TextOverflow
                  .ellipsis,

              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
                color:
                Color(
                  0xFF292637,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child:
      SingleChildScrollView(
        padding:
        const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,

          children: [
            Container(
              height: 100,
              width: 100,

              decoration:
              const BoxDecoration(
                color:
                Color(
                  0xFFF0EBFF,
                ),

                shape:
                BoxShape.circle,
              ),

              child: const Icon(
                Icons
                    .folder_open_outlined,

                color:
                Color(
                  0xFF6335D6,
                ),

                size: 50,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              "No Health Records Yet",

              textAlign:
              TextAlign.center,

              style:
              TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.w700,
                color:
                Color(
                  0xFF252332,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              "Your medical records will appear here.\n"
                  "Add your first health record to get started.",

              textAlign:
              TextAlign.center,

              style:
              TextStyle(
                fontSize: 13,
                height: 1.6,
                color:
                Color(
                  0xFF777384,
                ),
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            ElevatedButton.icon(
              onPressed: () {
                _showAddRecordDialog();
              },

              icon: const Icon(
                Icons.add_rounded,
              ),

              label: const Text(
                "Add First Record",
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

                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(
      String error,
      ) {
    return Center(
      child: SingleChildScrollView(
        padding:
        const EdgeInsets.all(
          25,
        ),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,

          children: [
            const Icon(
              Icons
                  .error_outline_rounded,

              color:
              Colors.redAccent,

              size: 55,
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              "Unable to load health records",

              textAlign:
              TextAlign.center,

              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              "Please check your internet connection "
                  "and Firestore configuration.",

              textAlign:
              TextAlign.center,

              style:
              TextStyle(
                fontSize: 13,
                color:
                Color(
                  0xFF777384,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            OutlinedButton(
              onPressed: () {
                setState(() {});
              },

              child:
              const Text(
                "Try Again",
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // --------------------------------------------------
            // DEBUG INFORMATION
            // --------------------------------------------------

            if (error.isNotEmpty)
              Container(
                width:
                double.infinity,

                padding:
                const EdgeInsets
                    .all(
                  12,
                ),

                decoration:
                BoxDecoration(
                  color:
                  Colors.red
                      .withOpacity(
                    0.05,
                  ),

                  borderRadius:
                  BorderRadius
                      .circular(
                    8,
                  ),

                  border:
                  Border.all(
                    color:
                    Colors.red
                        .withOpacity(
                      0.15,
                    ),
                  ),
                ),

                child:
                Text(
                  error,

                  style:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD RECORD DIALOG
  // ============================================================

  void _showAddRecordDialog() {
    final TextEditingController
    titleController =
    TextEditingController();

    final TextEditingController
    doctorController =
    TextEditingController();

    final TextEditingController
    hospitalController =
    TextEditingController();

    final TextEditingController
    descriptionController =
    TextEditingController();

    String selectedType =
        "Medical Report";

    DateTime selectedDate =
    DateTime.now();

    bool isSaving = false;

    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              title: const Text(
                "Add Health Record",

                style:
                TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              content: SizedBox(
                width: 500,

                child:
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      // ------------------------------------------
                      // TITLE
                      // ------------------------------------------

                      _dialogTextField(
                        controller:
                        titleController,

                        label:
                        "Record Title",

                        hint:
                        "e.g. Blood Test Report",

                        icon:
                        Icons
                            .description_outlined,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ------------------------------------------
                      // RECORD TYPE
                      // ------------------------------------------

                      DropdownButtonFormField<
                          String>(
                        value:
                        selectedType,

                        decoration:
                        _dialogInputDecoration(
                          "Record Type",
                          Icons
                              .category_outlined,
                        ),

                        items: const [
                          DropdownMenuItem(
                            value:
                            "Medical Report",
                            child: Text(
                              "Medical Report",
                            ),
                          ),

                          DropdownMenuItem(
                            value:
                            "Prescription",
                            child: Text(
                              "Prescription",
                            ),
                          ),

                          DropdownMenuItem(
                            value:
                            "Lab Test",
                            child: Text(
                              "Lab Test",
                            ),
                          ),

                          DropdownMenuItem(
                            value:
                            "Scan / Imaging",
                            child: Text(
                              "Scan / Imaging",
                            ),
                          ),

                          DropdownMenuItem(
                            value:
                            "Diagnosis",
                            child: Text(
                              "Diagnosis",
                            ),
                          ),

                          DropdownMenuItem(
                            value:
                            "Vaccination",
                            child: Text(
                              "Vaccination",
                            ),
                          ),

                          DropdownMenuItem(
                            value: "Other",
                            child: Text(
                              "Other",
                            ),
                          ),
                        ],

                        onChanged:
                        isSaving
                            ? null
                            : (
                            value,
                            ) {
                          if (value !=
                              null) {
                            setDialogState(
                                  () {
                                selectedType =
                                    value;
                              },
                            );
                          }
                        },
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ------------------------------------------
                      // DOCTOR
                      // ------------------------------------------

                      _dialogTextField(
                        controller:
                        doctorController,

                        label:
                        "Doctor Name",

                        hint:
                        "Enter doctor name",

                        icon:
                        Icons
                            .person_outline,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ------------------------------------------
                      // HOSPITAL
                      // ------------------------------------------

                      _dialogTextField(
                        controller:
                        hospitalController,

                        label:
                        "Hospital / Clinic",

                        hint:
                        "Enter hospital or clinic",

                        icon:
                        Icons
                            .local_hospital_outlined,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ------------------------------------------
                      // DATE
                      // ------------------------------------------

                      InkWell(
                        onTap:
                        isSaving
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
                            DateTime(
                              1900,
                            ),

                            lastDate:
                            DateTime
                                .now(),
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
                            "Record Date",
                            Icons
                                .calendar_today_outlined,
                          ),

                          child: Text(
                            _formatDateTime(
                              selectedDate,
                            ),

                            style:
                            const TextStyle(
                              fontSize: 14,
                              color:
                              Color(
                                0xFF292637,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ------------------------------------------
                      // DESCRIPTION
                      // ------------------------------------------

                      _dialogTextField(
                        controller:
                        descriptionController,

                        label:
                        "Description",

                        hint:
                        "Enter additional details",

                        icon:
                        Icons
                            .notes_outlined,

                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                // ------------------------------------------------
                // CANCEL
                // ------------------------------------------------

                TextButton(
                  onPressed:
                  isSaving
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },

                  child:
                  const Text(
                    "Cancel",
                  ),
                ),

                // ------------------------------------------------
                // SAVE
                // ------------------------------------------------

                ElevatedButton(
                  onPressed:
                  isSaving
                      ? null
                      : () async {
                    final String
                    title =
                    titleController
                        .text
                        .trim();

                    if (title
                        .isEmpty) {
                      _showMessage(
                        "Please enter a record title.",
                      );
                      return;
                    }

                    setDialogState(
                          () {
                        isSaving =
                        true;
                      },
                    );

                    final bool
                    success =
                    await _saveRecord(
                      title:
                      title,

                      recordType:
                      selectedType,

                      doctorName:
                      doctorController
                          .text
                          .trim(),

                      hospitalName:
                      hospitalController
                          .text
                          .trim(),

                      description:
                      descriptionController
                          .text
                          .trim(),

                      recordDate:
                      selectedDate,
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
                          isSaving =
                          false;
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
                    "Save Record",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DIALOG TEXT FIELD
  // ============================================================

  Widget _dialogTextField({
    required TextEditingController
    controller,

    required String label,

    required String hint,

    required IconData icon,

    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,

      maxLines: maxLines,

      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF292637),
      ),

      decoration:
      _dialogInputDecoration(
        label,
        icon,
      ).copyWith(
        hintText: hint,
      ),
    );
  }

  // ============================================================
  // DIALOG INPUT DECORATION
  // ============================================================

  InputDecoration
  _dialogInputDecoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(
        icon,

        color:
        const Color(
          0xFF7352B5,
        ),

        size: 20,
      ),

      filled: true,

      fillColor:
      const Color(
        0xFFFAF9FC,
      ),

      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          11,
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
          11,
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
          11,
        ),

        borderSide:
        const BorderSide(
          color:
          Color(0xFF7352B5),

          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // SAVE RECORD TO FIRESTORE
  // ============================================================

  Future<bool> _saveRecord({
    required String title,
    required String recordType,
    required String doctorName,
    required String hospitalName,
    required String description,
    required DateTime recordDate,
  }) async {
    // ----------------------------------------------------------
    // CURRENT USER
    // ----------------------------------------------------------

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        "You are not logged in.",
      );

      return false;
    }

    final String uid =
        currentUser.uid;

    debugPrint(
      "Saving health record for UID: $uid",
    );

    setState(() {
      _isAddingRecord = true;
    });

    try {
      // --------------------------------------------------------
      // SAVE RECORD
      // --------------------------------------------------------

      await FirebaseFirestore
          .instance
          .collection('healthRecords')
          .add({
        'patientId': uid,

        'title': title,

        'recordType': recordType,

        'doctorName': doctorName,

        'hospitalName': hospitalName,

        'description': description,

        'recordDate':
        Timestamp.fromDate(
          recordDate,
        ),

        'createdAt':
        FieldValue.serverTimestamp(),
      });

      debugPrint(
        "Health record saved successfully.",
      );

      if (!mounted) {
        return true;
      }

      _showSuccessMessage(
        "Health record added successfully!",
      );

      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        "================================================",
      );

      debugPrint(
        "FIREBASE ERROR WHILE SAVING RECORD",
      );

      debugPrint(
        "Code: ${e.code}",
      );

      debugPrint(
        "Message: ${e.message}",
      );

      debugPrint(
        "================================================",
      );

      if (mounted) {
        _showMessage(
          "Unable to save health record: ${e.message}",
        );
      }

      return false;
    } catch (e) {
      debugPrint(
        "Error saving health record: $e",
      );

      if (mounted) {
        _showMessage(
          "Unable to save health record. "
              "Please try again.",
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isAddingRecord = false;
        });
      }
    }
  }

  // ============================================================
  // VIEW RECORD DETAILS
  // ============================================================

  void _showRecordDetails(
      QueryDocumentSnapshot<
          Map<String, dynamic>>
      document,
      ) {
    final Map<String, dynamic> data =
    document.data();

    final String title =
        data['title']?.toString() ??
            "Health Record";

    final String recordType =
        data['recordType']?.toString() ??
            "Medical Record";

    final String doctorName =
        data['doctorName']?.toString() ??
            "";

    final String hospitalName =
        data['hospitalName']?.toString() ??
            "";

    final String description =
        data['description']?.toString() ??
            "";

    final Timestamp? recordDate =
    data['recordDate'] is Timestamp
        ? data['recordDate'] as Timestamp
        : null;

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Text(
            title,

            style:
            const TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF252332),
            ),
          ),

          content:
          SingleChildScrollView(
            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                _reportDetail(
                  "Record Type",
                  recordType,
                ),

                if (doctorName
                    .isNotEmpty)
                  _reportDetail(
                    "Doctor",
                    doctorName,
                  ),

                if (hospitalName
                    .isNotEmpty)
                  _reportDetail(
                    "Hospital / Clinic",
                    hospitalName,
                  ),

                if (recordDate != null)
                  _reportDetail(
                    "Record Date",
                    _formatDate(
                      recordDate,
                    ),
                  ),

                if (description
                    .isNotEmpty)
                  _reportDetail(
                    "Description",
                    description,
                  ),
              ],
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
                "Close",

                style:
                TextStyle(
                  color:
                  Color(
                    0xFF6335D6,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REPORT DETAIL
  // ============================================================

  Widget _reportDetail(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style:
            const TextStyle(
              fontSize: 11,
              color:
              Color(0xFF777384),
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            value,

            style:
            const TextStyle(
              fontSize: 14,
              color:
              Color(0xFF292637),
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  void _confirmDelete(
      String recordId,
      String recordTitle,
      ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title:
          const Text(
            "Delete Record",

            style:
            TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          content:
          Text(
            'Are you sure you want to delete "$recordTitle"?',

            style:
            const TextStyle(
              fontSize: 14,
              height: 1.5,
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
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  context,
                );

                await _deleteRecord(
                  recordId,
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
  // DELETE RECORD
  // ============================================================

  Future<void> _deleteRecord(
      String recordId,
      ) async {
    try {
      debugPrint(
        "Deleting health record: $recordId",
      );

      await FirebaseFirestore
          .instance
          .collection('healthRecords')
          .doc(recordId)
          .delete();

      debugPrint(
        "Health record deleted successfully.",
      );

      if (!mounted) {
        return;
      }

      _showSuccessMessage(
        "Health record deleted.",
      );
    } on FirebaseException catch (e) {
      debugPrint(
        "Firebase delete error: ${e.code}",
      );

      debugPrint(
        "Firebase delete message: ${e.message}",
      );

      if (mounted) {
        _showMessage(
          "Unable to delete the record: ${e.message}",
        );
      }
    } catch (e) {
      debugPrint(
        "Error deleting record: $e",
      );

      if (mounted) {
        _showMessage(
          "Unable to delete the record.",
        );
      }
    }
  }

  // ============================================================
  // RECORD ICON
  // ============================================================

  IconData _getRecordIcon(
      String type,
      ) {
    switch (type) {
      case "Prescription":
        return Icons
            .medication_outlined;

      case "Lab Test":
        return Icons
            .biotech_outlined;

      case "Scan / Imaging":
        return Icons
            .image_search_outlined;

      case "Diagnosis":
        return Icons
            .health_and_safety_outlined;

      case "Vaccination":
        return Icons
            .vaccines_outlined;

      case "Medical Report":
        return Icons
            .description_outlined;

      default:
        return Icons
            .folder_outlined;
    }
  }

  // ============================================================
  // DATE FORMAT
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

  String _formatDateTime(
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
              Icons
                  .check_circle_outline,
              color: Colors.white,
            ),

            const SizedBox(
              width: 10,
            ),

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
          seconds: 4,
        ),
      ),
    );
  }
}