import 'package:flutter/material.dart';
import 'staff/log.dart';
import 'students/log.dart';  // Import Student Login Page

class CommonLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),  // Adjusted padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             
              const SizedBox(height: 30),

              // Welcome Text with larger size
              Text(
                'Welcome to ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,  // Color for a rich feel
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Titus Attendance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,  // Color for a rich feel
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please choose your login option below.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // Student Login Button with gradient and shadow
              Container(
                height: 50,
                width: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.blue],  // Gradient effect
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15.0),  // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,  // Transparent button to show gradient
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to student login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudentLoginPage()),
                    );
                  },
                  child: const Text(
                    'Student',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white  // White text for contrast
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Staff Login Button with a modern color and shadow
              Container(
                height: 50,
                width: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.greenAccent, Colors.green],  // Green gradient for Staff button
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,  // Transparent button to show gradient
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to staff login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmployeeLoginPage()),
                    );
                  },
                  child: const Text(
                    'Staff',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white  // White text for contrast
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Footer Text with a subtle color and smaller size
              Text(
                '© 2025 Titus Attendance. All rights reserved.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
