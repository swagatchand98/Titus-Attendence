import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:final_titus_attendence_1/students/log.dart'; // Assuming this contains the Student model

class NotificationItem {
  final int id;
  final String message;
  final DateTime date;

  NotificationItem({
    required this.id,
    required this.message,
    required this.date,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      message: json['message']?.toString() ?? '',
      date: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }
}

class StudentListScreen extends StatefulWidget {
  final int studentId;
  final Student student;
  final String studentUserid;

  const StudentListScreen({
    Key? key,
    required this.studentId,
    required this.student,
    required this.studentUserid,
  }) : super(key: key);

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  String errorMessage = '';

  Future<void> fetchNotifications() async {
    final notificationUrl =
        'https://titusattendence.com/proxy.php?table=studentnotification';

    try {
      final response = await http.get(Uri.parse(notificationUrl));

      if (response.statusCode == 200) {
        try {
          final jsonStartIndex = response.body.indexOf('[');
          final jsonString = response.body.substring(jsonStartIndex);
          final List<dynamic> data = jsonDecode(jsonString);

          setState(() {
            notifications = data
                .where((item) =>
                    item['user_id'].toString().trim() ==
                    widget.studentUserid.trim())
                .map((item) => NotificationItem.fromJson(item))
                .toList();

            // Sort notifications by latest date first
            notifications.sort((a, b) => b.date.compareTo(a.date));

            isLoading = false;
          });
        } catch (e) {
          setState(() {
            errorMessage = 'Error parsing response: $e';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to fetch notifications: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> _refreshPage() async {
    await Future.delayed(const Duration(seconds: 2));
    await fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8.0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : notifications.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications available',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return _buildNotificationCard(notification)
                                .animate()
                                .fade(duration: 600.ms)
                                .scale(duration: 400.ms, curve: Curves.easeOut);
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.9),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.date_range, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Date: ${notification.date}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
