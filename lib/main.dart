import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialee_sphere/login.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Platform-aware base URL.
///
/// • Web (Chrome/Edge/Firefox)   → localhost
/// • Windows / macOS / Linux     → localhost
/// • iOS simulator               → localhost
/// • Android emulator            → 10.0.2.2
/// • Physical device             → override kManualBaseUrl with your LAN IP
/// ─────────────────────────────────────────────────────────────────────────────
const String kManualBaseUrl = ""; // e.g. "http://192.168.1.10/socialee_sphere"

String get kBaseUrl {
  if (kManualBaseUrl.isNotEmpty) return kManualBaseUrl;

  if (kIsWeb) return "http://192.168.1.17/socialee_sphere";

  try {
    if (Platform.isAndroid) {
      // Android emulator maps host machine to 10.0.2.2
      return "http://192.168.1.17/socialee_sphere";
    }
  } catch (_) {
    // Platform not available (e.g. Web) — ignore
  }

  // iOS, Windows, macOS, Linux
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
///  1. Reads saved agency credentials (SharedPreferences / localStorage).
///  2. Re-validates them against login.php.
///  3. Routes to AgencyHomeScreen on success, LogIN otherwise.
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

    // No saved credentials → login screen
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

      // Safe JSON parsing
      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        _goToLogin();
        return;
      }

      if (response.statusCode == 200 && body['status'] == true) {
        final agency = (body['data'] as Map).cast<String, dynamic>();

        await prefs.setInt('agency_id', (agency['id'] as num?)?.toInt() ?? 0);
        await prefs.setString('agency_name', agency['agency_name'] ?? '');
        await prefs.setString('owner_name', agency['owner_name'] ?? '');
        await prefs.setString('agency_email', agency['email'] ?? savedEmail);

        _goToHome(agency);
      } else {
        // Invalid / unverified → wipe credentials
        await _clearSession(prefs);
        _goToLogin();
      }
    } catch (_) {
      // Network error → keep credentials, fall back to login
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
      MaterialPageRoute(builder: (_) => LogIN()),
    );
  }

  void _goToHome(Map<String, dynamic> agency) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AgencyHomeScreen(agency: agency)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 18),
            Text(
              "Checking session...",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Placeholder home screen — replace with your real agency dashboard.
/// ─────────────────────────────────────────────────────────────────────────────
class AgencyHomeScreen extends StatelessWidget {
  final Map<String, dynamic> agency;
  const AgencyHomeScreen({super.key, required this.agency});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LogIN()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agency Dashboard"),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                "Welcome, ${agency['owner_name'] ?? 'Owner'}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text("Agency: ${agency['agency_name'] ?? ''}"),
              const SizedBox(height: 4),
              Text("Email: ${agency['email'] ?? ''}"),
            ],
          ),
        ),
      ),
    );
  }
}