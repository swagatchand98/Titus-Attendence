import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'log1.dart'; // ✅ Ensure this file exists
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("b5224068-c7c4-41a5-82f2-73d100817a3c");
  OneSignal.Notifications.requestPermission(true);

  // ✅ Foreground listener (let OneSignal auto-show with sound)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    // ⚠ Do NOT call event.preventDefault() — this allows default behavior
    print("Foreground notification received: ${event.notification.title}");
  });

  // ✅ Notification click handler
  OneSignal.Notifications.addClickListener((event) {
    print("Notification clicked: ${event.notification.notificationId}");
  });

  runApp(MyApp());
}



// ✅ Ask for notification permission (Android 13+)
Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}


/// 🔹 Root App Widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notifications',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CommonLoginPage(), // ✅ Ensure this class exists
    );
  }
}

/// 🔹 Main Home Page (Shows Player ID & Counter) 
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String? _playerId = "Fetching Player ID...";

  @override
  void initState() {
    super.initState();
    fetchPlayerId();
  }

  /// 🔹 Fetch OneSignal Player ID
  void fetchPlayerId() async {
    String? playerId = await OneSignal.User.pushSubscription.id;
    setState(() {
      _playerId = playerId ?? "Player ID not available";
    });
    print("Player ID: $_playerId");
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('OneSignal Player ID:'),
            Text(
              _playerId!,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}                        
