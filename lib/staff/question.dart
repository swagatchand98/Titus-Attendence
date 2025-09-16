import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: UploadScreen(),
    );
  }
}

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? selectedFile;
  Uint8List? webFileBytes;
  String? filename;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController teacherName = TextEditingController();
  final TextEditingController subject = TextEditingController();
  final TextEditingController className = TextEditingController();
  final TextEditingController unit = TextEditingController();
  final TextEditingController upload_date = TextEditingController();
  final TextEditingController unit_date = TextEditingController();
  final TextEditingController message = TextEditingController();
  final TextEditingController uploadedBy = TextEditingController();


 List<String> classNames = [];
  String? selectedClass;

   List<String> unitNames = ["F.A1", "F.A2", "F.A3", "S.A1", "S.A2", "OTHERS"];
  String? selectedUnit;

  DateTime? selectedDate;
  DateTime? uploadedDate;

  @override
  void initState() {
    super.initState();
    fetchClassNames();
  }

 Future<void> fetchClassNames() async {
  final url = Uri.parse("https://titusattendence.com/filter.php");

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body); // Decode as Map

      // Check if 'data' key exists and is a list
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
        List<dynamic> dataList = jsonResponse['data']; // Extract the list

        Set<String> classSet = dataList.map((item) => item['class_name'].toString()).toSet();

        setState(() {
          classNames = classSet.toList();
        });
      } else {
        throw Exception("Invalid response format: 'data' key missing or not a list");
      }
    } else {
      throw Exception("Failed to load classes: ${response.statusCode}");
    }
  } catch (e) {
    print("Error fetching classes: $e");
  }
}

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        filename = result.files.single.name;
        webFileBytes = kIsWeb ? result.files.single.bytes : null;
        selectedFile = !kIsWeb ? File(result.files.single.path!) : null;
      });
    }
  }

 Future<void> uploadFile() async {
    if (!_formKey.currentState!.validate()) return;

    if ((selectedFile == null && webFileBytes == null) || filename == null) {
      showSnackbar("⚠️ Please select a file first!", Colors.redAccent);
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://titusattendence.com/proxy.php?table=uploaded_files"),
      );

      request.fields.addAll({
        'teacher_name': teacherName.text,
        'subject': subject.text,
        'class_name': selectedClass ?? '',  // ✅ Use selectedClass
        'unit': selectedUnit ?? '',  // ✅ Use selectedUnit
        'Uplaod_date': selectedDate.toString(),
        'unit_date': uploadedDate.toString(),
        'file_name': filename!,
        'message': message.text,
        'uploaded_by': uploadedBy.text,
      });

      request.headers['Content-Type'] = 'multipart/form-data; charset=UTF-8';

      if (!kIsWeb && selectedFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path));
      }

      if (kIsWeb && webFileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', webFileBytes!, filename: filename));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        showSnackbar("✅ File uploaded successfully!", Colors.green);
      } else {
        showSnackbar("❌ Upload failed! Error: $responseBody", Colors.redAccent);
      }
    } catch (e) {
      showSnackbar("⚠️ Error: $e", Colors.redAccent);
    }
  }

  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 Future<void> pickDate(BuildContext context, bool isUnitDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isUnitDate) {
          selectedDate = pickedDate;
        } else {
          uploadedDate = pickedDate;
        }
      });
    }
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 190, 232, 234),
        centerTitle: true,
        elevation: 5.0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTextField(teacherName, "Teacher Name"),
                buildTextField(subject, "Subject"),
                buildDropdown("Class Name", classNames, selectedClass, (value) {
                  setState(() {
                    selectedClass = value;
                  });
                }),
                buildDropdown("Unit", unitNames, selectedUnit, (value) {
                  setState(() {
                    selectedUnit = value;
                  });
                }),
                buildDatePicker(" Upload Date", selectedDate, () => pickDate(context, true)),
                buildDatePicker(" Unit Date", uploadedDate, () => pickDate(context, false)),
                buildTextField(message, "Message"),
                buildTextField(uploadedBy, "Uploaded By"),
                SizedBox(height: 15),
                if (filename != null)
                  Text("Selected File: $filename", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(height: 15),
                buildButton("Select File", pickFile),
                SizedBox(height: 10),
                buildButton("Upload File", uploadFile, isPrimary: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          suffixIcon: Icon(Icons.calendar_today),
        ),
        controller: TextEditingController(text: date != null ? "${date.toLocal()}".split(' ')[0] : ""),
        onTap: onTap,
      ),
    );
  }
}
  Widget buildDropdown(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      value: selectedValue,
      items: [
        DropdownMenuItem(value: null, child: Text("Select $label", style: TextStyle(color: Colors.grey))),
        ...items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      validator: (value) => value == null ? "Please select $label" : null,
    ),
  );
}


  Widget buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: (value) => value!.isEmpty ? "Field cannot be empty" : null,
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onPressed, {bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: isPrimary ? Colors.deepPurple : Colors.grey[300],
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
        ),
        onPressed: onPressed,
        child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

