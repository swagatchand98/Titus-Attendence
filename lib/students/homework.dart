import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart'; // Import to open files
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'log.dart';

class Homework {
  final int id;
  final String subject;
  final String className;
  final String sectionId;
  final String classwork;
  final String message;
  final String post_date;
  final String submit_date;
  final String fileName;
  final String filePath;

  Homework({
    required this.id,
    required this.subject,
    required this.className,
    required this.sectionId,
    required this.classwork,
    required this.message,
    required this.post_date,
    required this.submit_date,
    required this.fileName,
    required this.filePath,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      className: json['class_name'] ?? '',
      sectionId: json['section_id'] ?? '',
      classwork: json['classwork'] ?? '',
      message: json['message'] ?? '',
      post_date: json['post_date'] ?? '',
      submit_date: json['submit_date'] ?? '',
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
    );
  }
}

class HomeworkPage extends StatefulWidget {
  final Student student;
  const HomeworkPage({Key? key, required this.student}) : super(key: key);

  @override
  _HomeworkPageState createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  late Future<List<Homework>> futureHomework;
  String? downloadingFileName;
  String? downloadedFilePath;

  @override
  void initState() {
    super.initState();
    futureHomework = fetchHomework();
  }

  Future<List<Homework>> fetchHomework() async {
    final url = 'https://titusattendence.com/proxy.php?table=homework_uploads';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final jsonStartIndex = responseBody.indexOf('[');
        final jsonString = responseBody.substring(jsonStartIndex);

        final List<dynamic> data = jsonDecode(jsonString);
        final allHomework = data.map((item) => Homework.fromJson(item)).toList();
         // Sorting homework messages so that the latest ones appear on top
      allHomework.sort((a, b) => b.id.compareTo(a.id)); 
        return allHomework.where((homework) => homework.sectionId == widget.student.sectionId).toList();
      } else {
        throw Exception('Failed to load homework data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

Future<void> _downloadFile(BuildContext context, String filePath, String fileName) async {
  setState(() => downloadingFileName = fileName);

  try {
    final fullUrl = 'https://titusattendence.com/$filePath'.replaceAll('..', '');
    final dio = Dio();
    late String savePath;

    // Use app-private storage for both Android and iOS
    final directory = await getApplicationDocumentsDirectory();
    savePath = '${directory.path}/$fileName';

    await dio.download(fullUrl, savePath);

    setState(() {
      downloadingFileName = null;
      downloadedFilePath = savePath;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded: $fileName'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => _openFile(savePath),
        ),
      ),
    );
  } catch (e) {
    setState(() => downloadingFileName = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download failed!')),
    );
  }
}


  void _openFile(String filePath) {
    OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
    appBar: AppBar(
        title:const Text('Homeworks',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 190, 232, 234),
        centerTitle: true,
        elevation: 5.0,
      ),
       body: RefreshIndicator(
      onRefresh: _refreshHomework,
      child: FutureBuilder<List<Homework>>(
        future: futureHomework,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(fontSize: 16, color: Colors.redAccent),
            ));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No homework found for your section',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ));
          } else {
            final sortedHomework = snapshot.data!;
            sortedHomework.sort((a, b) => b.post_date.compareTo(a.post_date)); // Sort to show latest on top

            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: sortedHomework.length,
              itemBuilder: (context, index) {
                final homework = sortedHomework[index];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(2, 2)),
                    ],
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(
                      homework.subject,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class: ${homework.className}, Section: ${homework.sectionId}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            'Classwork: ${homework.classwork}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            'Message: ${homework.message}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            'Post Date: ${homework.post_date}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            'Submit Date: ${homework.submit_date}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    trailing: downloadingFileName == homework.fileName
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.download_rounded, color: Colors.blueAccent),
                            onPressed: () => _downloadFile(context, homework.filePath, homework.fileName),
                          ),
                  ),
                );
              },
            );
          }
        },
      ),
    ),
  );
}

Future<void> _refreshHomework() async {
  setState(() {
    futureHomework = fetchHomework(); // Refresh the future to reload data
  });
}

}
