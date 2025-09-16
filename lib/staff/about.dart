import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'log.dart';
class EmployeeProfilePage extends StatefulWidget {
  final Employee employee;

  const EmployeeProfilePage({Key? key, required this.employee}) : super(key: key);

  @override
  _EmployeeProfilePageState createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  File? _pickedImage;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSavedProfileImage();
  }

  // Load saved profile image from SharedPreferences
  Future<void> _loadSavedProfileImage() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedImagePath = _prefs.getString('profile_image_${widget.employee.employeeUserid}');
    if (savedImagePath != null && savedImagePath.isNotEmpty) {
      setState(() {
        _pickedImage = File(savedImagePath);
      });
    }
  }

  // Save the selected profile image to SharedPreferences
  Future<void> _saveProfileImage(String imagePath) async {
    await _prefs.setString('profile_image_${widget.employee.employeeUserid}', imagePath);
  }

  // Pick an image using the ImagePicker
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
      _saveProfileImage(image.path);
    }
  }

  // Refresh the page when pulled down
  Future<void> _refreshPage() async {
    // Simulate a delay for 2 seconds to show the refresh indicator
    await Future.delayed(const Duration(seconds: 2));

    // Simulate reloading the profile image or any other refresh logic you want to perform
    await _loadSavedProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title:const Text('profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 190, 232, 234),
        centerTitle: true,
        elevation: 5.0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,  // Trigger refresh logic here
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo Section with ImagePicker
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (widget.employee.employeePhoto != 'N/A' &&
                          widget.employee.employeePhoto.isNotEmpty
                          ? NetworkImage(
                          'https://titusattendence.com/Admin/${widget.employee.employeePhoto}')
                          : null) as ImageProvider?,
                      backgroundColor: Colors.grey[200],
                      child: (_pickedImage == null &&
                          (widget.employee.employeePhoto == 'N/A' ||
                              widget.employee.employeePhoto.isEmpty))
                          ? const Icon(Icons.person, size: 70, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // General Information Section
              _buildProfileSection(
                title: "General Information",
                details: [
                  _buildInfoRow("Gender", widget.employee.gender),
                  _buildInfoRow("Date of Birth", widget.employee.dob),
                  _buildInfoRow("Email", widget.employee.email),
                  _buildInfoRow("Contact No", widget.employee.contactNo),
                  _buildInfoRow("Address", widget.employee.address),
                  _buildInfoRow("Father/Husband Name", widget.employee.husbandFatherName),
                  _buildInfoRow("Mother Name", widget.employee.motherName),
                ],
              ),

              const SizedBox(height: 20),

              // Employment Information Section
              _buildProfileSection(
                title: "Employment Information",
                details: [
                  _buildInfoRow("Category", widget.employee.categories),
                  _buildInfoRow("Remark", widget.employee.remark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build profile sections with title and details
  Widget _buildProfileSection({
    required String title,
    required List<Widget> details,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 10,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      shadowColor: Colors.blueAccent.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            ...details,
          ],
        ),
      ),
    );
  }

  // Helper method to build individual info rows
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
