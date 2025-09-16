import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

class Holiday {
  final int id;
  final String holidayName;
  final String fromDate;
  final String toDate;
  final String holidayFor;
  final String description;

  Holiday({
    required this.id,
    required this.holidayName,
    required this.fromDate,
    required this.toDate,
    required this.holidayFor,
    required this.description,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'],
      holidayName: json['holiday_name'],
      fromDate: json['from_date'],
      toDate: json['to_date'],
      holidayFor: json['holiday_for'],
      description: json['description'],
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Holiday List',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
      ),
      home: StaffHolidays(),
    );
  }
}

class StaffHolidays extends StatefulWidget {
  @override
  _StaffHolidaysState createState() => _StaffHolidaysState();
}

class _StaffHolidaysState extends State<StaffHolidays> {
 List<Holiday> holidays = [];
  String userRole = "STAFF";

  @override
  void initState() {
    super.initState();
    fetchHolidays();
  }

  Future<void> fetchHolidays() async {
    final response = await http.get(Uri.parse('https://titusattendence.com/proxy.php?table=holidays'));

    if (response.statusCode == 200) {
      String cleanedResponse = response.body.replaceFirst("Received table: holidays<br>", "");
      try {
        List<dynamic> data = json.decode(cleanedResponse);
        setState(() {
          holidays = data
              .map((holidayJson) => Holiday.fromJson(holidayJson))
              .where((holiday) => userRole == "STAFF" && (holiday.holidayFor == "STAFF" || holiday.holidayFor == "BOTH"))
              .toList();
                 // 🆕 Sort by date (latest holidays first)
          holidays.sort((a, b) => b.fromDate.compareTo(a.fromDate));
        });
          for (var holiday in holidays) {
          _insertHolidayIntoAttendance(holiday);
        }
      } catch (e) {
        print("Error parsing JSON: $e");
      }
    } else {
      print('Failed to load holidays');
      throw Exception('Failed to load holidays');
    }
  }

  Future<void> _refreshPage() async {
    await Future.delayed(const Duration(seconds: 2));
    await fetchHolidays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holidays', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 8.0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: holidays.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: holidays.length,
                itemBuilder: (context, index) {
                  final holiday = holidays[index];
                  return _buildHolidayCard(holiday)
                      .animate()
                      .fade(duration: 600.ms)
                      .scale(duration: 400.ms, curve: Curves.easeOut);
                },
              ),
      ),
    );
  }

  Widget _buildHolidayCard(Holiday holiday) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.9),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              holiday.holidayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.date_range, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'From: ${holiday.fromDate}  To: ${holiday.toDate}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              holiday.description,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _insertHolidayIntoAttendance(Holiday holiday) async {
  final insertUrl = 'https://titusattendence.com/proxy.php?table=employees_attendance';

  // Check if the holiday is already added
  final checkResponse = await http.get(Uri.parse('$insertUrl&holiday_name=${holiday.holidayName}'));
  if (checkResponse.statusCode == 200) {
    List<dynamic> existingRecords = jsonDecode(checkResponse.body);
    if (existingRecords.isNotEmpty) {
      print("Holiday '${holiday.holidayName}' already exists in attendance. Skipping insertion.");
      return;
    }
  }

  // Prepare the data to insert
  Map<String, String> requestBody = {
    'employee_id': 'ALL',  // Apply to all students
    'attendance_date': holiday.fromDate,
    'status': 'SL',  // Marking holiday status
    'description': holiday.holidayName,
  };

  try {
    final response = await http.post(
      Uri.parse(insertUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      print("Holiday '${holiday.holidayName}' inserted successfully into attendance.");
    } else {
      print("Failed to insert holiday attendance: ${response.body}");
    }
  } catch (e) {
    print("Error inserting holiday attendance: $e");
  }
}
