import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

import 'log.dart' show Employee;

class Attendance {
  final int id;
  final int employeeId;
  final String name;
  final String status;
  final String date;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.status,
    required this.date,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      date: json['attendance_date'] ?? '',
    );
  }
}

class StaffAttendancePage extends StatefulWidget {
  final int employeeId;
  final Employee employee;

  const StaffAttendancePage({Key? key, required this.employeeId, required this.employee}) : super(key: key);

  @override
  _StaffAttendancePageState createState() => _StaffAttendancePageState();
}

class _StaffAttendancePageState extends State<StaffAttendancePage> {
   List<Attendance> attendanceData = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<DateTime, List<Attendance>> _attendanceMap = {};
  Set<DateTime> _holidayDates = {}; 
  int presentCount = 0;
  int absentCount = 0;
  int sundayCount = 0;
  int workingDaysCount = 0;
  int holidayCount = 0;
  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchHolidaysAndAttendance(selectedMonth);
  }

  Future<void> fetchHolidaysAndAttendance(DateTime month) async {
    await fetchHolidays(month);
    await fetchAttendance(month);
  }

Future<void> fetchAttendance(DateTime month) async {
  final attendanceUrl = 'https://titusattendence.com/proxy.php?table=students_attendance';

  try {
    final response = await http.get(Uri.parse(attendanceUrl));

    if (response.statusCode == 200) {
      String responseBody = response.body.trim();

      // Remove extra text before JSON array
      if (responseBody.contains('[')) {
        responseBody = responseBody.substring(responseBody.indexOf('['));
      } else {
        setState(() {
          errorMessage = 'Invalid response format: No JSON array found.';
          isLoading = false;
        });
        return;
      }

      final List<dynamic> data = jsonDecode(responseBody);

      List<Attendance> updatedData = data
          .where((item) =>
              item['employee_id'].toString() == widget.employeeId.toString() &&
              DateTime.parse(item['attendance_date']).month == month.month &&
              DateTime.parse(item['attendance_date']).year == month.year)
          .map((item) => Attendance.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        attendanceData = updatedData;
        _attendanceMap.clear();
        presentCount = 0;
        absentCount = 0;
        sundayCount = 0;
        workingDaysCount = 0;
        holidayCount = _holidayDates.length; 

        for (var record in attendanceData) {
          final date = DateTime.tryParse(record.date);
          if (date != null) {
            DateTime normalizedDay = DateTime(date.year, date.month, date.day);
            if (!_attendanceMap.containsKey(normalizedDay)) {
              _attendanceMap[normalizedDay] = [];
            }
            _attendanceMap[normalizedDay]!.add(record);

            if (record.status == 'P') {
              presentCount++;
            } else if (record.status == 'A') {
              absentCount++;
            }
          }
        }

        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
        for (int i = 1; i <= daysInMonth; i++) {
          DateTime day = DateTime(month.year, month.month, i);
          if (day.weekday == DateTime.sunday) {
            sundayCount++;
          } else if (!_holidayDates.contains(day)) {
            workingDaysCount++;
          }
        }

        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Failed to load attendance data.';
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Error: $e';
      isLoading = false;
    });
  }
}

 Future<void> fetchHolidays(DateTime month) async {
  final holidayUrl = 'https://titusattendence.com/proxy.php?table=holidays';

  try {
    final response = await http.get(Uri.parse(holidayUrl));

    if (response.statusCode == 200) {
      String responseBody = response.body.trim();

      // Ensure the response contains a valid JSON array
      if (responseBody.contains('[')) {
        responseBody = responseBody.substring(responseBody.indexOf('['));
      } else {
        print('Error: No valid JSON found in response.');
        return;
      }

      final List<dynamic> data = jsonDecode(responseBody);

      Set<DateTime> holidays = {};

      for (var item in data) {
        DateTime fromDate = DateTime.parse(item['from_date']);
        DateTime toDate = DateTime.parse(item['to_date']);

        // Add all dates between from_date and to_date
        for (DateTime day = fromDate;
            day.isBefore(toDate) || day.isAtSameMomentAs(toDate);
            day = day.add(const Duration(days: 1))) {
          if (day.month == month.month && day.year == month.year) {
            holidays.add(DateTime(day.year, day.month, day.day)); // Normalize date
          }
        }
      }

      setState(() {
        _holidayDates = holidays;
      });

    } else {
      print('Failed to load holidays. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching holidays: $e');
  }
}


 Color _getDayColor(DateTime day) {
  DateTime normalizedDay = DateTime(day.year, day.month, day.day);

  if (_holidayDates.contains(normalizedDay)) {
    return const Color(0xFF4FF9B6); // Light green for holidays
  }
  if (day.weekday == DateTime.sunday) {
    return Color(0xFF52f3fa); 
  }
  if (_attendanceMap.containsKey(normalizedDay)) {
    final attendanceRecords = _attendanceMap[normalizedDay]!;
    if (attendanceRecords.isNotEmpty) {
      final attendanceRecord = attendanceRecords.first;
      if (attendanceRecord.status == 'P') {
        return Colors.green; 
      } else if (attendanceRecord.status == 'A') {
        return Colors.red; 
      }
    }
  }
  return Colors.grey; 
}

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 190, 232, 234),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                      children: [
                       TableCalendar(
  focusedDay: selectedMonth,
  firstDay: DateTime.utc(2020, 1, 1),
  lastDay: DateTime.utc(2099, 12, 31),
  calendarFormat: CalendarFormat.month, // Force Month View
  availableCalendarFormats: const {
    CalendarFormat.month: 'Month', // Remove week toggle
  },
  headerStyle: HeaderStyle(
    formatButtonVisible: false, // Hide "2 weeks" dropdown
  ),
  onPageChanged: (focusedDay) {
    setState(() {
      selectedMonth = focusedDay; // Update selected month
    });
    fetchHolidaysAndAttendance(selectedMonth); // Automatically fetch data
  },
  daysOfWeekVisible: false, // Optional: Hide weekday labels
  calendarBuilders: CalendarBuilders(
    defaultBuilder: (context, day, focusedDay) {
      return Container(
        margin: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: _getDayColor(day), // Automatically update colors
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(day.day.toString(), style: const TextStyle(color: Colors.black)),
        ),
      );
    },
  ),
),


                        const SizedBox(height: 6),
                     Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), // Reduced padding
                    width: MediaQuery.of(context).size.width * 0.9, // Responsive width
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Makes the container fit the content
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _buildStatCard('Present', presentCount, Colors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard('Absent', absentCount, Colors.red)),
                            
                        const SizedBox(height: 12), // Reduced spacing
                        Expanded(child: _buildStatCard('Sunday', sundayCount, const Color(0xFF52f3fa))),
                          ],
                        ),
                        const SizedBox(height: 12), // Reduced spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _buildStatCard('Working Days', workingDaysCount, Colors.blueAccent)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard('Holidays', holidayCount, const Color(0xFF4FF9B6))),
                          ],
                        ), // Removed Expanded and Center
                      ],
                    ),
                  ),
                  
                  
                      ],
                    ),
                ),
              ),
    );
  }


  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.black)),
            Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
