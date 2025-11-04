import 'dart:convert';
import 'package:final_titus_attendence_1/students/db.dart';
import 'package:final_titus_attendence_1/utils/mock_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart' show OneSignal;

class Student {
  var id;
  final String studentName;
  final String className;
  var sectionId;
  final String studentCategory;
  final String gender;
  var dob;
  var rollNumber;
  final String fatherName;
  var fatherContact;
  final String motherName;
  var motherContact;
  final String address;
  final String bloodGroup;
  final String city;
  final String webSms;
  var androidPassword;
  final String studentPhoto;
  var rfId;
  final String remark;
  var studentUserid;

  Student({
    required this.id,
    required this.studentName,
    required this.className,
    required this.sectionId,
    required this.studentCategory,
    required this.gender,
    required this.dob,
    required this.rollNumber,
    required this.fatherName,
    required this.fatherContact,
    required this.motherName,
    required this.motherContact,
    required this.address,
    required this.bloodGroup,
    required this.city,
    required this.webSms,
    required this.androidPassword,
    required this.studentPhoto,
    required this.rfId,
    required this.remark,
    required this.studentUserid,
  });
factory Student.fromJson(Map<String, dynamic> json) {
  return Student(
    id: json['id'] ?? 0,
    studentName: json['student_name'] ?? 'N/A',
    className: json['class_name'] ?? 'N/A',
    sectionId: json['section_id'] ?? 'N/A',
    studentCategory: json['student_category'] ?? 'N/A',
    gender: json['gender'] ?? 'N/A',
    dob: json['dob'] ?? 'N/A',
    rollNumber: json['roll_number'] ?? 'N/A',
    fatherName: json['father_name'] ?? 'N/A',
    fatherContact: json['father_contact'] ?? 'N/A',
    motherName: json['mother_name'] ?? 'N/A',
    motherContact: json['mother_contact'] ?? 'N/A',
    address: json['address'] ?? 'N/A',
    bloodGroup: json['blood_group'] ?? 'N/A',
    city: json['city'] ?? 'N/A',
    webSms: json['web_sms'] ?? 'N/A',
    androidPassword: json['android_password'] ?? 'N/A',
    studentPhoto: json['student_photo'] ?? 'N/A',
    rfId: json['rf_id'] ?? 'N/A',
    remark: json['remark'] ?? 'N/A',
    studentUserid: json['student_userid']?.toString() ?? 'N/A',  // ✅ Force String
  );
}


  Map<String, dynamic> toJson() => {
        "id": id,
        "student_name": studentName,
        "class_name": className,
        "section_id": sectionId,
        "student_category": studentCategory,
        "gender": gender,
        "dob": dob,
        "roll_number": rollNumber,
        "father_name": fatherName,
        "father_contact": fatherContact,
        "mother_name": motherName,
        "mother_contact": motherContact,
        "address": address,
        "blood_group": bloodGroup,
        "city": city,
        "web_sms": webSms,
        "android_password": androidPassword,
        "student_photo": studentPhoto,
        "rf_id": rfId,
        "remark": remark,
        "student_userid": studentUserid,
      };
}

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  _StudentLoginPageState createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isPasswordVisible = false; // ✅ Initialize password visibility state

@override
void initState() {
  super.initState();
  _checkLoginStatus(); // Check if user is already logged in
}


Future<void> _checkLoginStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('user_id');
  String? studentJson = prefs.getString('student_data');

  if (userId != null && studentJson != null) {
    Student student = Student.fromJson(jsonDecode(studentJson));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StudentDashboard(student: student, studentId: userId),
      ),
    );
  }
}

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Username and password cannot be empty';
      });
      return;
    }

    // First, try mock authentication
    final mockAuth = MockAuthService.instance;
    if (mockAuth.authenticateStudent(username, password)) {
      await _loginWithMockData();
      return;
    }

    // If mock auth fails, try regular authentication
    final loginUrl = 'https://titusattendence.com/proxy.php?table=students';

    try {
      final response = await http.get(Uri.parse(loginUrl));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final jsonStartIndex = responseBody.indexOf('[');
        final jsonString = responseBody.substring(jsonStartIndex);

        List<dynamic> data = jsonDecode(jsonString);

        var studentData = data.firstWhere(
          (student) =>
              student['student_userid'] != null &&
              student['android_password'] != null &&
              student['student_userid'].toLowerCase().trim() ==
                  username.toLowerCase() &&
              student['android_password'].trim() == password,
          orElse: () => null,
        );

        if (studentData != null) {
          // Check if student_userid is null and use mock data as fallback
          if (studentData['student_userid'] == null) {
            print("⚠️ Student userid is null, using mock authentication as fallback");
            await _loginWithMockData();
            return;
          }

          Student student = Student.fromJson(studentData);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', student.studentUserid.toString());
          await prefs.setString('student_data', jsonEncode(student.toJson()));

          _sendUserIdAndPlayerId(student.studentUserid);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboard(
                student: student, 
                studentId: student.studentUserid.toString(),
              ),
            ),
          );
        } else {
          // If regular auth fails, try mock auth as fallback
          if (mockAuth.shouldUseMockAuth()) {
            print("⚠️ Regular authentication failed, trying mock authentication");
            if (mockAuth.authenticateStudent(username, password)) {
              await _loginWithMockData();
              return;
            }
          }
          
          setState(() {
            _errorMessage = 'Invalid username or password. Try: aradhya_student / 12345 for demo';
          });
        }
      } else {
        // If server is unreachable, try mock auth as fallback
        print("⚠️ Server unreachable, trying mock authentication");
        if (mockAuth.authenticateStudent(username, password)) {
          await _loginWithMockData();
          return;
        }
        
        setState(() {
          _errorMessage = 'Failed to connect to server. Try: aradhya_student / 12345 for demo';
        });
      }
    } catch (e) {
      // If there's an error, try mock auth as fallback
      print("⚠️ Error occurred, trying mock authentication: $e");
      if (mockAuth.authenticateStudent(username, password)) {
        await _loginWithMockData();
        return;
      }
      
      setState(() {
        _errorMessage = 'Error: $e. Try: aradhya_student / 12345 for demo';
      });
    }
  }

  Future<void> _loginWithMockData() async {
    final mockAuth = MockAuthService.instance;
    final mockStudentData = mockAuth.getMockStudentData();
    
    Student student = Student.fromJson(mockStudentData);
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', student.studentUserid.toString());
    await prefs.setString('student_data', jsonEncode(student.toJson()));
    await prefs.setString('is_mock_user', 'true'); // Flag to identify mock user

    // Send mock user data to server (optional)
    _sendUserIdAndPlayerId(student.studentUserid);

    print("✅ Mock authentication successful for ${student.studentName}");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboard(
          student: student,
          studentId: student.studentUserid.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Student Login',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 5.0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Colors.black),
                      filled: true,
                      fillColor: Colors.blue[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock, color: Colors.black),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.blue[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Login',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 20),
                  // Demo credentials info card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Demo Credentials',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Username: aradhya_student\nPassword: 12345',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


  /// 🔹 Send Player ID and User ID to Server
   Future<void> _sendUserIdAndPlayerId(String userId) async {
    String? playerId = await OneSignal.User.pushSubscription.id;

    if (userId.isEmpty || playerId == null || playerId.isEmpty) {
      print("❌ Error: user_id or player_id is missing!");
      return;
    }

    final url = Uri.parse("https://titusattendence.com/save_player_id.php");

     try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"user_id": userId, "player_id": playerId},
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print(
          "🔹 Server Response: ${response.body.isNotEmpty ? response.body : '(Empty Response)'}");

      if (response.statusCode == 200 && response.body.contains("success")) {
        print("✅ Player ID updated successfully!");
      } else {
        print("❌ Failed to send Player ID. Server Response: ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending Player ID: $e");
    }
  }
