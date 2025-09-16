import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
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
      home: Homeworks(),
    );
  }
}

class Homeworks extends StatefulWidget {
  @override
  _HomeworksState createState() => _HomeworksState();
}

class _HomeworksState extends State<Homeworks> {
  File? selectedFile;
  Uint8List? webFileBytes;
  String? filename;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController subject = TextEditingController();
  final TextEditingController className = TextEditingController();
  final TextEditingController sectionId = TextEditingController();
  final TextEditingController classwork = TextEditingController();
  final TextEditingController message = TextEditingController();
  final TextEditingController postDate = TextEditingController();
  final TextEditingController submitDate = TextEditingController();
  final TextEditingController uploadedBy = TextEditingController();

  List<String> classNames = [];
  List<String> sectionIds = [];
  String? selectedClass;
  String? selectedSection;

  DateTime? selectedDate;
  DateTime? uploadedDate;

  @override
  void initState() {
    super.initState();
    fetchClassAndSections();
  }

  Future<void> fetchClassAndSections() async {
    final url = Uri.parse("https://titusattendence.com/filter.php");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> dataList = jsonResponse['data'];

          Set<String> classSet = {};
          Set<String> sectionSet = {};

          for (var item in dataList) {
            if (item.containsKey('class_name')) {
              classSet.add(item['class_name'].toString());
            }
            if (item.containsKey('section_id')) {
              sectionSet.add(item['section_id'].toString());
            }
          }

          setState(() {
            classNames = classSet.toList();
            sectionIds = sectionSet.toList();
          });
        } else {
          throw Exception(
              "Invalid response format: 'data' key missing or not a list");
        }
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
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
        Uri.parse(
            "https://titusattendence.com/proxy.php?table=homework_uploads"),
      );

      request.fields.addAll({
        'subject': subject.text,
        'class_name': selectedClass ?? '', // ✅ Use selectedClass
        'section_id': selectedSection ?? '', // ✅ Use selectedSection
        'file_name': filename!,
        'classwork': classwork.text,
        'message': message.text,
        'post_date': selectedDate.toString(),
        'submit_date': selectedDate.toString(),
        'uploaded_by': uploadedBy.text,
      });

      request.headers['Content-Type'] = 'multipart/form-data; charset=UTF-8';

      if (!kIsWeb && selectedFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('file', selectedFile!.path));
      }

      if (kIsWeb && webFileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', webFileBytes!,
            filename: filename));
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
        content: Text(message,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
        title: const Text('Home Works',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 190, 232, 234),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                buildTextField(subject, "Subject"),
                buildDropdown("Class Name", classNames, selectedClass, (value) {
                  setState(() {
                    selectedClass = value;
                  });
                }),
                buildDropdown("Section ID", sectionIds, selectedSection,
                    (value) {
                  setState(() {
                    selectedSection = value;
                  });
                }),
                buildTextField(classwork, "Classwork"),
                buildTextField(message, "Message"),
                buildDatePicker(
                    "Post Date", selectedDate, () => pickDate(context, true)),
                buildDatePicker(
                    "Submit Date", uploadedDate, () => pickDate(context, false)),
                buildTextField(uploadedBy, "Uploaded By"),
                SizedBox(height: 15),
                if (filename != null)
                  Text("Selected File: $filename",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(height: 15),
                buildButton("📁 Select File", pickFile),
                SizedBox(height: 10),
                buildButton("⬆ Upload File", uploadFile, isPrimary: true),
              ],
            ),
          ),
        ),
      ),
    );
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
        controller: TextEditingController(
            text: date != null ? "${date.toLocal()}".split(' ')[0] : ""),
        onTap: onTap,
      ),
    );
  }
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
        fillColor: Colors.white,
      ),
      validator: (value) => value!.isEmpty ? "Field cannot be empty" : null,
    ),
  );
}

Widget buildButton(String text, VoidCallback onPressed,
    {bool isPrimary = false}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isPrimary ? Colors.deepPurple : Colors.grey[300],
        foregroundColor: isPrimary ? Colors.white : Colors.black87,
        elevation: 3,
      ),
      onPressed: onPressed,
      child: Text(text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    ),
  );
}

Widget buildDropdown({
  required String label,
  required List<String> items,
  required String? selectedValue,
  required Function(String?) onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      value: selectedValue,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? "Please select $label" : null,
    ),
  );
}
