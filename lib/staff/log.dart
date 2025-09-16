import 'dart:math';
import 'package:onesignal_flutter/onesignal_flutter.dart' show OneSignal;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../staff/db.dart'; // Ensure this is the correct import
import '../log1.dart';

class Employee {
  final int id;
  final String employeeName;
  final String gender;
  final String dob;
  final String husbandFatherName;
  final String motherName;
  final String email;
  final String contactNo;
  final String address;
  final String rfId;
  final String designation;
  final String categories;
  final String remark;
  final String employeePhoto;
  final String employeeUserid;
  final String password;
  final String createdAt;
  final String updatedAt;

  Employee({
    required this.id,
    required this.employeeName,
    required this.gender,
    required this.dob,
    required this.husbandFatherName,
    required this.motherName,
    required this.email,
    required this.contactNo,
    required this.address,
    required this.rfId,
    required this.designation,
    required this.categories,
    required this.remark,
    required this.employeePhoto,
    required this.employeeUserid,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
  return Employee(
    id: json['id'] ?? 0,
    employeeName: json['employee_name'] ?? 'N/A',
    gender: json['gender'] ?? 'N/A',
    dob: json['dob'] ?? 'N/A',
    husbandFatherName: json['husband_father_name'] ?? 'N/A',
    motherName: json['mother_name'] ?? 'N/A',
    email: json['email'] ?? 'N/A',
    contactNo: json['contact_no'] ?? 'N/A',
    address: json['address'] ?? 'N/A',
    rfId: json['rf_id'] ?? 'N/A',
    designation: json['designation'] ?? 'N/A',
    categories: json['categories'] ?? 'N/A',
    remark: json['remark'] ?? 'N/A',
    employeePhoto: json['employee_photo'] ?? 'N/A',
    employeeUserid: json['employee_userid']?.toString() ?? 'N/A', // ✅ Force String
    password: json['password'] ?? 'N/A',
    createdAt: json['created_at'] ?? 'N/A',
    updatedAt: json['updated_at'] ?? 'N/A',
  );
}


  Map<String, dynamic> toJson() => {
        "id": id,
        "employee_name": employeeName,
        "gender": gender,
        "dob": dob,
        "husband_father_name": husbandFatherName,
        "mother_name": motherName,
        "email": email,
        "contact_no": contactNo,
        "address": address,
        "rf_id": rfId,
        "designation": designation,
        "categories": categories,
        "remark": remark,
        "employee_photo": employeePhoto,
        "employee_userid": employeeUserid,
        "password": password,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}

class EmployeeLoginPage extends StatefulWidget {
  const EmployeeLoginPage({super.key});

  @override
  _EmployeeLoginPageState createState() => _EmployeeLoginPageState();
}

class _EmployeeLoginPageState extends State<EmployeeLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? employeeJson = prefs.getString('employee_data');

    if (userId != null && employeeJson != null) {
      Employee employee = Employee.fromJson(jsonDecode(employeeJson));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EmployeeDashboard(employeeUserid: userId, employee: employee),
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

    final loginUrl = 'https://titusattendence.com/proxy.php?table=employees';

    try {
      final response = await http.get(Uri.parse(loginUrl));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final jsonStartIndex = responseBody.indexOf('[');
        final jsonString = responseBody.substring(jsonStartIndex);

        List<dynamic> data = jsonDecode(jsonString);

        var employeeData = data.firstWhere(
          (employee) =>
              employee['employee_userid'] != null &&
              employee['password'] != null &&
              employee['employee_userid'].toLowerCase().trim() ==
                  username.toLowerCase() &&
              employee['password'].trim() == password,
          orElse: () => null,
        );

        if (employeeData != null) {
          Employee employee = Employee.fromJson(employeeData);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          // await prefs.setString('user_id', employee.employeeUserid);
          await prefs.setString('user_id', employee.employeeUserid.toString()); // ✅ Ensure String
          await prefs.setString('employee_data', jsonEncode(employee.toJson()));

          _sendUserIdAndPlayerId(employee.employeeUserid);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeDashboard(
                  employeeUserid: employee.employeeUserid, employee: employee),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Invalid username or password';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to the server';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _sendUserIdAndPlayerId(String userId) async {
    String? playerId = await OneSignal.User.pushSubscription.id;

    if (userId.isEmpty || playerId == null || playerId.isEmpty) {
      print("❌ Error: user_id or player_id is missing!");
      return;
    }

    final url = Uri.parse("https://titusattendence.com/save_playerid_staff.php");

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

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Staff Login',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
