import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'log.dart';
// Import the Student class

class StudentProfilePage extends StatefulWidget {
  final Student student;

  const StudentProfilePage({Key? key, required this.student, required studentUserid}) : super(key: key);

  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  File? _imageFile;
  late SharedPreferences _prefs;
  bool _isUploading = false; // Flag to indicate upload status

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto(); // Load the profile photo when the screen loads
  }

  ImageProvider _getImageProvider() {
    if (_imageFile != null) {
      return FileImage(_imageFile!); // Show picked image
    } else if (widget.student.studentPhoto.isNotEmpty) {
      return NetworkImage('https://titusattendence.com/Admin/uploads/${widget.student.studentPhoto}');
    } else {
      return AssetImage('assets/profile_placeholder.png'); // Default placeholder
    }
  }

  // Load profile photo from SharedPreferences or fallback to Network Image
  Future<void> _loadProfilePhoto() async {
    _prefs = await SharedPreferences.getInstance();
    final photoPath = _prefs.getString('profile_photo${widget.student.id}');
    if (photoPath != null && photoPath.isNotEmpty) {
      setState(() {
        _imageFile = File(photoPath); // Load the image from the path in SharedPreferences
      });
    } else {
      // If no photo is saved in SharedPreferences, fallback to network image
      setState(() {
        _imageFile = null; // Ensure _imageFile is null if using network image
      });
    }
  }

  // Save profile photo to SharedPreferences
  Future<void> _saveProfilePhoto(String path) async {
    await _prefs.setString('profile_photo${widget.student.id}', path);
  }

  // Pick an image from the gallery and upload it immediately
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Update UI with selected image
        _isUploading = true; // Show loading spinner 
      });
      await _saveProfilePhoto(pickedFile.path); // Save image locally

      await _uploadPhoto(pickedFile); // Upload image to the server
    }
  }


  // Method to upload the selected photo to the server
  Future<void> _uploadPhoto(XFile pickedFile) async {
    if (_imageFile != null) {
      var uri = Uri.parse('https://titusattendence.com/proxy.php?table=students');
      var request = http.MultipartRequest('POST', uri);

      var pic = await http.MultipartFile.fromPath(
        'photo', pickedFile.path, // 'photo' is the field name on the server side
        filename: pickedFile.name,
      );
      request.files.add(pic);
      request.fields['student_id'] = widget.student.id.toString();  // Add student ID

      try {
        var response = await request.send();

        if (response.statusCode == 200) {
          setState(() {
            _isUploading = false; // Hide loading spinner after successful upload
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photo uploaded successfully!')),
          );
        } else {
          setState(() {
            _isUploading = false; // Hide loading spinner if upload fails
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload photo!')),
          );
        }
      } catch (e) {
        setState(() {
          _isUploading = false; // Hide loading spinner in case of error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e')),
        );
      }
    } else {
      setState(() {
        _isUploading = false; // Hide loading spinner if no image is selected
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected for upload!')),
      );
    }
  }

  // Refresh function for pull-to-refresh
  Future<void> _onRefresh() async {
    await Future.delayed(Duration(seconds: 2));
    _loadProfilePhoto(); // Reload the profile photo from SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Text('Student Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 190, 232, 234),
        centerTitle: true,
        elevation: 5.0,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo section with edit option
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: _getImageProvider(), // Use the new function
                      backgroundColor: Colors.grey[200],
                      child: _imageFile == null && widget.student.studentPhoto.isEmpty
                          ? Icon(Icons.person, size: 70, color: Colors.white) // Placeholder icon
                          : null,
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage, // Pick image on tap
                        child: Container(
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
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // If uploading, show a progress indicator
              if (_isUploading) CircularProgressIndicator(),

              // General information
              _buildCard(
                title: 'General Information',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Student Name', widget.student.studentName),
                    _buildInfoRow('Roll Number', widget.student.rollNumber),
                    _buildInfoRow('Gender', widget.student.gender),
                    _buildInfoRow('Date of Birth', widget.student.dob),
                  ],
                ),
              ),

              // Parent details
              _buildCard(
                title: 'Parent Details',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Father', widget.student.fatherName),
                    _buildInfoRow('Mother', widget.student.motherName),
                    _buildInfoRow('Father\'s Contact', widget.student.fatherContact),
                    _buildInfoRow('Mother\'s Contact', widget.student.motherContact),
                  ],
                ),
              ),

              // Academic information
              _buildCard(
                title: 'Academic Information',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Class', widget.student.className),
                    _buildInfoRow('Section', widget.student.sectionId),
                    _buildInfoRow('Category', widget.student.studentCategory),
                    _buildInfoRow('Blood Group', widget.student.bloodGroup),
                    _buildInfoRow('City', widget.student.city),
                    _buildInfoRow('RF ID', widget.student.rfId),
                    _buildInfoRow('Remark', widget.student.remark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a card
  Widget _buildCard({required String title, required Widget content}) {
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
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  // Helper method to build each info row
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
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            ),
        );
    }
}
