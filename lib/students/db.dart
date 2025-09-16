import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about.dart';
import 'attendence.dart';
import 'holidays.dart';
import 'leaves.dart';
import 'log.dart';
import 'notification.dart';
import 'homework.dart';
import 'downloads.dart';

class StudentDashboard extends StatefulWidget {
  final Student student;

  const StudentDashboard({Key? key, required this.student,  required String studentId,}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool hasNewNotifications = false;
  String? latestNotificationId;
  int unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
   
  }

   /// Simulates receiving a new notification
  void onNewNotificationReceived() {
    setState(() {
      unreadNotificationCount++;
    });
  }

  /// Marks all notifications as read
  void markNotificationsAsRead() {
    setState(() {
      unreadNotificationCount = 0;
    });
  }



  @override
  Widget build(BuildContext context) {
    var hasNewNotifications = unreadNotificationCount > 0;
    return Scaffold(
      appBar: AppBar(
leading: IconButton(
  onPressed: () async {
    bool confirmLogout = await _showLogoutConfirmationDialog(context);
    if (confirmLogout) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear saved user session

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudentLoginPage()),
      );
    }
  },
  icon: Icon(Icons.logout),
),



        title: const Text('Sudent Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 190, 232, 234),
        centerTitle: true,
        elevation: 5.0,
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>StudentListScreen(
                          student: widget.student,
                          studentId: widget.student.id, 
                          studentUserid: widget.student.studentUserid,
                        )),
              ).then((_) => markNotificationsAsRead()); // Mark as read after viewing
            },
            icon: Stack(
              children: [
                Icon(Icons.notifications, size: 30),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadNotificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
              ],
            ),
          )
        ],
      ),
      backgroundColor: Colors.deepPurple.shade50,
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 190, 232, 234),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Welcome, ${widget.student.studentName}!',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildDashboardOption(
                  'View Profile',
                  Icons.person,
                  'Check your personal details',
                  Colors.purple.shade100,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                             StudentProfilePage(
                      studentUserid: widget.student.studentUserid,
                      student: widget.student))),
              ),
              _buildDashboardOption(
                  'View Attendance',
                  Icons.check_circle,
                  'Track your attendance records',
                  Colors.green.shade100,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => StudentAttendancePage(
                      student: widget.student, studentId: widget.student.id)))),
              _buildDashboardOption(
                  'Apply Leave',
                  Icons.access_alarm,
                  'Apply for your leave here',
                  Colors.orange.shade100,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>LeaveRequestPage(student: widget.student, 
                  studentId: widget.student.id, 
                  )
                             ))),
              _buildDashboardOption(
                  'View Holidays',
                  Icons.beach_access,
                  'View your holiday list',
                  Colors.blue.shade100,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => StudentHolidayScreen()))),
              _buildDashboardOption(
                  'Home Work',
                  Icons.file_copy,
                  'Check your Home works here.',
                  Colors.red.shade100,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomeworkPage(student: widget.student)))),
              _buildDashboardOption(
                  'Downloads',
                  Icons.download,
                  'View all your downloaded files',
                  Colors.teal.shade100,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DownloadsPage()))),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOption(
      String title, IconData icon, String description, Color cardColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 4,
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.5), // Background color for the icon
                  borderRadius: BorderRadius.circular(30), // Rounded shape
                  border: Border.all(color: Colors.black, width: 2), // Border color and width
                ),
                child: Icon(icon, size: 30, color: Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
        ),
        elevation: 5,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated logout image
               
              Text(
                "Are you sure you want to log out?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54,
                fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHoverButton(context, "No", Colors.redAccent, Colors.redAccent, false),
                  _buildHoverButton(context, "Yes", Colors.redAccent, Colors.redAccent, true),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ) ?? false; // Default to false if dialog is dismissed
}

Widget _buildHoverButton(BuildContext context, String text, Color initialColor, Color hoverColor, bool isYesButton) {
  return StatefulBuilder(
    builder: (context, setState) {
      Color buttonColor = initialColor;

      return MouseRegion(
        onEnter: (_) => setState(() => buttonColor = hoverColor),
        onExit: (_) => setState(() => buttonColor = initialColor),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(isYesButton); // Yes -> true, No -> false
          },
          child: Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    },
  );
}
