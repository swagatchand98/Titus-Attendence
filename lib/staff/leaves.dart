import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'log.dart';

class LeaveRequestPage2 extends StatefulWidget {
  final Employee employee;
  final int employeeId;
  const LeaveRequestPage2({Key? key, required this.employee, required this.employeeId}) : super(key: key);

  @override
  _LeaveRequestPage2State createState() => _LeaveRequestPage2State();
}

class _LeaveRequestPage2State extends State<LeaveRequestPage2> {
    final _formKey = GlobalKey<FormState>();
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _leaveFromController = TextEditingController();
  final TextEditingController _leaveToController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _totalLeaveDaysController = TextEditingController();

  bool isLoading = false;
  int _leaveDays = 0;

   Future<void> sendLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final leaveData = {
      "employee_userid": widget.employeeId,
      "employee_name": _staffNameController.text,
      "email": widget.employee.email,
      "contact_no": _contactController.text,
      "categories": widget.employee.categories,
      "designation": _designationController.text,
      "leave_from": _leaveFromController.text,
      "leave_to": _leaveToController.text,
      "total_leave_days": _leaveDays.toString(),
      "reason": _reasonController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('https://titusattendence.com/proxy.php?table=staffleaves'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(leaveData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request submitted successfully!')),
        );
        await _markAbsentForLeavePeriod();
        _clearFields();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit leave request.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAbsentForLeavePeriod() async {
    if (_leaveFromController.text.isEmpty || _leaveToController.text.isEmpty) {
      print('Error: Leave date fields are empty.');
      return;
    }

    DateTime leaveFrom = DateTime.parse(_leaveFromController.text);
    DateTime leaveTo = DateTime.parse(_leaveToController.text);

    for (DateTime date = leaveFrom;
        date.isBefore(leaveTo.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
      
      // Check if attendance already exists for the date
      final checkResponse = await http.get(
        Uri.parse('https://titusattendence.com/proxy.php?table=employees_attendance&employee_id=${widget.employeeId}&attendance_date=${date.toLocal().toString().split(' ')[0]}'),
      );

      if (checkResponse.statusCode == 200 && checkResponse.body.contains("A")) {
        print("Attendance already marked for ${date.toLocal().toString().split(' ')[0]}");
        continue;
      }

      final attendanceData = {
        "employee_id": widget.employeeId,
        "name": _staffNameController.text.isNotEmpty ? _staffNameController.text : "N/A",
        "gender": widget.employee.gender ?? "N/A",
        "contact_no": _contactController.text.isNotEmpty ? _contactController.text : "N/A",
        "email": widget.employee.email ?? "N/A",
        "attendance_date": date.toLocal().toString().split(' ')[0],
        "status": "A", // Absent
        "category": widget.employee.categories ?? "N/A",
      };

      try {
        final attendanceResponse = await http.post(
          Uri.parse('https://titusattendence.com/proxy.php?table=employees_attendance'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(attendanceData),
        );

        if (attendanceResponse.statusCode == 200) {
          print("Attendance marked as Absent for: ${date.toLocal().toString().split(' ')[0]}");
        } else {
          throw Exception('Failed to insert attendance: ${attendanceResponse.body}');
        }
      } catch (e) {
        print('Error updating attendance: $e');
      }
    }
  }

  
     void _clearFields() {
    _staffNameController.clear();
    _designationController.clear();
    _leaveFromController.clear();
    _leaveToController.clear();
    _reasonController.clear();
    _contactController.clear();
    _totalLeaveDaysController.clear();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
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
    if (_leaveFromController.text.isNotEmpty && _leaveToController.text.isNotEmpty) {
      final leaveFrom = DateTime.parse(_leaveFromController.text);
      final leaveTo = DateTime.parse(_leaveToController.text);
      final difference = leaveTo.difference(leaveFrom).inDays;
      setState(() {
        _leaveDays = difference >= 0 ? difference + 1 : 0;
        _totalLeaveDaysController.text = _leaveDays.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        elevation: 5.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_staffNameController, 'Staff Name', Icons.person),
                    _buildTextField(_designationController, 'Designation', Icons.work),
                    _buildDateField(_leaveFromController, 'Leave From'),
                    _buildDateField(_leaveToController, 'Leave To'),
                    _buildTextField(_reasonController, 'Reason', Icons.edit),
                    _buildTextField(_contactController, 'Contact Number', Icons.phone),
                    _buildTextField(_totalLeaveDaysController, 'Total Leave Days', Icons.calendar_today, readOnly: true),
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

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, {bool readOnly = false}) {
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
        validator: (value) => value == null || value.isEmpty ? 'Please enter $labelText' : null,
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
        validator: (value) => value == null || value.isEmpty ? 'Please select $labelText' : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.blue.shade900,
        ),
        onPressed: isLoading ? null : sendLeaveRequest,
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Submit Leave Request', style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}

