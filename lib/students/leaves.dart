

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'log.dart';

class LeaveRequestPage extends StatefulWidget {
  final Student student;
  final int studentId;
  const LeaveRequestPage(
      {Key? key, required this.student, required this.studentId})
      : super(key: key);

  @override
  LeaveRequestPageState createState() => LeaveRequestPageState();
}

class LeaveRequestPageState extends State<LeaveRequestPage> {
  final _formKey = GlobalKey<FormState>();
  List<String> classNames = [];
  List<String> sectionIds = [];
  String? selectedClass;
  String? selectedSection;

  final TextEditingController _student_id = TextEditingController();
  final TextEditingController _student_name = TextEditingController();
  final TextEditingController _class_name = TextEditingController();
  final TextEditingController _section_id = TextEditingController();
  final TextEditingController _student_userid = TextEditingController();
  final TextEditingController _father_name = TextEditingController();
  final TextEditingController _father_contact = TextEditingController();
  final TextEditingController _leave_from = TextEditingController();
  final TextEditingController _leave_to = TextEditingController();
  final TextEditingController _total_leave = TextEditingController();
  final TextEditingController _reason = TextEditingController();

  bool isLoading = false;
  int _leaveDays = 0;

  void _printFormInputs() {
    print("\n--- Form Inputs ---");
    print("Student Name: ${_student_name.text}");
    print("Class Name: ${_class_name.text}");
    print("Section ID: ${_section_id.text}");
    print("Student UserID: ${_student_userid.text}");
    print("Father Name: ${_father_name.text}");
    print("Father Contact: ${_father_contact.text}");
    print("Leave From: ${_leave_from.text}");
    print("Leave To: ${_leave_to.text}");
    print("Total Leave Days: $_leaveDays");
    print("Reason: ${_reason.text}");
  }

  Future<void> sendLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    print("\n--- Sending Leave Request ---");
    _printFormInputs();

    setState(() => isLoading = true);

    final leaveData = {
      "student_id":widget.student.id,
      "student_name": widget.student.studentName,
      "class_name": selectedClass,
      "section_id": selectedSection,
      "student_userid": widget.student.studentUserid,
      "father_name": _father_name.text,
      "father_contact": _father_contact.text,
      "leave_from": _leave_from.text,
      "leave_to": _leave_to.text,
      "total_leave_days": _leaveDays.toString(),
      "reason": _reason.text,
    };

    print("Leave request payload: $leaveData");

    try {
      final response = await http.post(
        Uri.parse('https://titusattendence.com/proxy.php?table=leaves'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(leaveData),
      );

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        await _markAbsentForLeavePeriod();
        // _clearFields();
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAbsentForLeavePeriod() async {
    print("\n--- Marking Attendance Absent ---");
    if (_leave_from.text.isEmpty || _leave_to.text.isEmpty) return;

    DateTime leaveFrom = DateTime.parse(_leave_from.text);
    DateTime leaveTo = DateTime.parse(_leave_to.text);

    for (DateTime date = leaveFrom;
        date.isBefore(leaveTo.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
      print("Processing date: ${date.toLocal().toString().split(' ')[0]}");

      final attendanceData = {
        "student_id": widget.studentId,
        "name":widget.student.studentName,
        "class_id":selectedClass,
        "section_id":selectedSection,
        "roll_number"
        "father_name":_father_name.text,
        "attendance_date": date.toLocal().toString().split(' ')[0],
        "status": "A",
      };

      print("Sending attendance update: $attendanceData");

      try {
        await http.post(
          Uri.parse(
              'https://titusattendence.com/proxy.php?table=students_attendance'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(attendanceData),
        );
      } catch (e) {
        print("Error updating attendance: $e");
      }
    }
  }


  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = pickedDate.toLocal().toString().split(' ')[0];
        _calculateLeaveDays();
      });
    }
  }

  void _calculateLeaveDays() {
    if (_leave_from.text.isNotEmpty && _leave_to.text.isNotEmpty) {
      final leaveFrom = DateTime.parse(_leave_from.text);
      final leaveTo = DateTime.parse(_leave_to.text);
      final difference = leaveTo.difference(leaveFrom).inDays;
      setState(() {
        _leaveDays = difference >= 0 ? difference + 1 : 0;
        _total_leave.text = _leaveDays.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchClassAndSections();
  }

  Future<void> fetchClassAndSections() async {
    final url = Uri.parse("https://titusattendence.com/filter.php");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] is List) {
          Set<String> classSet = {};
          Set<String> sectionSet = {};

          for (var item in jsonResponse['data']) {
            if (item['class_name'] != null) {
              classSet.add(item['class_name'].toString());
            }
            if (item['section_id'] != null) {
              sectionSet.add(item['section_id'].toString());
            }
          }

          setState(() {
            classNames = classSet.toList();
            sectionIds = sectionSet.toList();
          });
        }
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        elevation: 5.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                        _student_name, 'Student Name', Icons.person),
                    buildDropdown("Class", classNames, selectedClass,
                        (value) => setState(() => selectedClass = value)),
                    buildDropdown("Section", sectionIds, selectedSection,
                        (value) => setState(() => selectedSection = value)),
                    _buildTextField(
                        _father_name, 'Father Name', Icons.person_outline),
                    _buildTextField(
                        _father_contact, 'Contact Number', Icons.phone),
                    _buildDateField(_leave_from, 'Leave From'),
                    _buildDateField(_leave_to, 'Leave To'),
                    _buildTextField(_reason, 'Reason', Icons.edit),
                    _buildTextField(
                        _total_leave, 'Total Leave Days', Icons.calendar_today,
                        readOnly: true),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        value: selectedValue,
        items: [
          DropdownMenuItem(
              value: null,
              child:
                  Text("Select $label", style: TextStyle(color: Colors.grey))),
          ...items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
        ],
        onChanged: onChanged,
        validator: (value) => value == null ? "Please select $label" : null,
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String labelText, IconData icon,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.blue.shade900),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $labelText' : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String labelText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade900),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onTap: () => _selectDate(context, controller),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select $labelText' : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.blue.shade900,
        ),
        onPressed: isLoading ? null : sendLeaveRequest,
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Submit Leave Request',
                style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}


