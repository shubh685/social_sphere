// main.dart
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialee_sphere/login.dart';
import 'package:socialee_sphere/dashboard.dart'; // Ensure your dashboard is imported

/// ─────────────────────────────────────────────────────────────────────────────
/// Platform-aware base URL.
/// ─────────────────────────────────────────────────────────────────────────────
const String kManualBaseUrl = "http://192.168.1.17/socialee_sphere";

String get kBaseUrl {
  if (kManualBaseUrl.isNotEmpty) return kManualBaseUrl;

  if (kIsWeb) return "http://192.168.1.17/socialee_sphere";

  try {
    if (Platform.isAndroid) {
      return "http://10.0.2.2/socialee_sphere";
    }
  } catch (_) {
    // Platform not available — ignore
  }

  // Windows, macOS, Linux, iOS
  return "http://localhost/socialee_sphere";
}

String get kLoginEndpoint => "$kBaseUrl/login.php";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Socialee Sphere',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AutoLoginGate(),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// AutoLoginGate
///  1. Reads saved credentials (SharedPreferences / browser localStorage).
///  2. Re-validates them against login.php.
///  3. Routes to Dashboard on success, LogIN otherwise.
/// ─────────────────────────────────────────────────────────────────────────────
class AutoLoginGate extends StatefulWidget {
  const AutoLoginGate({super.key});

  @override
  State<AutoLoginGate> createState() => _AutoLoginGateState();
}

class _AutoLoginGateState extends State<AutoLoginGate> {
  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  Future<void> _attemptAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('agency_email');
    final savedPassword = prefs.getString('agency_password');

    // No saved credentials → route directly to login screen
    if (savedEmail == null ||
        savedEmail.isEmpty ||
        savedPassword == null ||
        savedPassword.isEmpty) {
      _goToLogin();
      return;
    }

    try {
      final response = await http
          .post(
        Uri.parse(kLoginEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": savedEmail,
          "password": savedPassword,
        }),
      )
          .timeout(const Duration(seconds: 12));

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        _goToLogin();
        return;
      }

      if (response.statusCode == 200 && body['status'] == true) {
        final agency = (body['data'] as Map).cast<String, dynamic>();

        // Update stored session data if needed
        await prefs.setInt('agency_id', (agency['id'] as num?)?.toInt() ?? 0);
        await prefs.setString('agency_name', agency['agency_name'] ?? '');
        await prefs.setString('owner_name', agency['owner_name'] ?? '');
        await prefs.setString('agency_email', agency['email'] ?? savedEmail);

        _goToDashboard();
      } else {
        // Invalid or expired credentials → wipe session and prompt login
        await _clearSession(prefs);
        _goToLogin();
      }
    } catch (_) {
      // Network failure or backend timeout → fallback to login safely
      _goToLogin();
    }
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove('agency_email');
    await prefs.remove('agency_password');
    await prefs.remove('agency_id');
    await prefs.remove('agency_name');
    await prefs.remove('owner_name');
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LogIN()),
    );
  }

  void _goToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Dashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                color: Color(0xFF00F0FF),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 18),
            Text(
              "Checking session...",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}