import 'dart:convert';

class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  static MockAuthService get instance => _instance;

  // Mock student data provided by the user
  final Map<String, dynamic> _mockStudentData = {
    "id": 1,
    "student_name": "ARADHYA CHOUDHARY ",
    "class_name": "LKG",
    "section_id": "A",
    "student_category": "BC",
    "gender": "Female",
    "dob": null,
    "roll_number": "02",
    "father_name": "SANTOSH CHOUDHARY ",
    "father_contact": "99887766",
    "mother_name": "Rajeshwari",
    "mother_contact": "1234567890",
    "address": null,
    "blood_group": "B+",
    "city": "Bangalore",
    "web_sms": "Yes",
    "android_password": "12345",
    "student_photo": "uploads/Screenshot (1276).png",
    "rf_id": "3400306A4E20",
    "remark": "",
    "created_at": "2025-04-09 01:13:55",
    "student_userid": null,
    "player_id": "2c6d8615-96ca-4d5a-949a-97a73ca2238b"
  };

  // Mock credentials for the student
  final Map<String, String> _mockCredentials = {
    "username": "aradhya_student",
    "password": "12345"
  };

  /// Check if the provided credentials match the mock student
  bool authenticateStudent(String username, String password) {
    return _mockCredentials["username"] == username.toLowerCase().trim() &&
           _mockCredentials["password"] == password.trim();
  }

  /// Get mock student data
  Map<String, dynamic> getMockStudentData() {
    // Create a copy and assign a mock student_userid since it's null
    Map<String, dynamic> studentData = Map.from(_mockStudentData);
    studentData["student_userid"] = "mock_student_001";
    return studentData;
  }

  /// Get mock credentials for reference
  Map<String, String> getMockCredentials() {
    return Map.from(_mockCredentials);
  }

  /// Check if mock auth should be used (when regular auth fails)
  bool shouldUseMockAuth() {
    return true; // For now, always allow mock auth as fallback
  }

  /// Generate a mock student userid
  String generateMockStudentUserId() {
    return "mock_student_${_mockStudentData['id']}_${DateTime.now().millisecondsSinceEpoch}";
  }
}
