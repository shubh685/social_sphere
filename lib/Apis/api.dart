import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.17/socialee_sphere";

  static const String loginUrl      = "$baseUrl/login.php";
  static const String registerUrl   = "$baseUrl/register.php";
  static const String forgotPwdUrl  = "$baseUrl/forgot_pwd.php";

  /// Returns device time in "YYYY-MM-DD HH:MM:SS" (matches MySQL DATETIME).
  static String _deviceTimestamp() {
    final now = DateTime.now();
    final y  = now.year.toString().padLeft(4, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final d  = now.day.toString().padLeft(2, '0');
    final h  = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    final s  = now.second.toString().padLeft(2, '0');
    return "$y-$mo-$d $h:$mi:$s";
  }

  static Future<Map<String, dynamic>> _post(
      String url,
      Map<String, dynamic> body, {
        String? deviceTimestamp,
      }) async {
    try {
      final ts = (deviceTimestamp != null && deviceTimestamp.isNotEmpty)
          ? deviceTimestamp
          : _deviceTimestamp();

      // Single canonical key the PHP normalizer reads.
      body['device_datetime'] = ts;

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;

      return {"status": false, "message": "Invalid server response format"};
    } catch (e) {
      return {"status": false, "message": "Network error: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _post(loginUrl, {
      "email": email,
      "password": password,
    });
  }

  static Future<Map<String, dynamic>> registerSendOtp({
    required String agencyName,
    required String ownerName,
    required String email,
    String purpose = "REGISTRATION_STEP_1",
    String? deviceTimestamp,
  }) async {
    return await _post(
      registerUrl,
      {
        "action": "send_otp",
        "agency_name": agencyName,
        "owner_name": ownerName,
        "email": email,
        "purpose": purpose,
      },
      deviceTimestamp: deviceTimestamp,
    );
  }

  static Future<Map<String, dynamic>> registerVerifyOtp({
    required String email,
    required String otp,
    String purpose = "REGISTRATION_STEP_1",
    String? deviceTimestamp,
  }) async {
    return await _post(
      registerUrl,
      {
        "action": "verify_otp",
        "email": email,
        "otp": otp,
        "purpose": purpose,
      },
      deviceTimestamp: deviceTimestamp,
    );
  }

  static Future<Map<String, dynamic>> registerComplete({
    required String email,
    required String password,
    String? deviceTimestamp,
  }) async {
    return await _post(
      registerUrl,
      {
        "action": "complete_registration",
        "email": email,
        "password": password,
      },
      deviceTimestamp: deviceTimestamp,
    );
  }

  static Future<Map<String, dynamic>> forgotSendOtp({
    required String email,
    String? deviceTimestamp,
  }) async {
    return await _post(
      forgotPwdUrl,
      {"action": "send_otp", "email": email},
      deviceTimestamp: deviceTimestamp,
    );
  }

  static Future<Map<String, dynamic>> forgotVerifyOtp({
    required String email,
    required String otp,
    String? deviceTimestamp,
  }) async {
    return await _post(
      forgotPwdUrl,
      {"action": "verify_otp", "email": email, "otp": otp},
      deviceTimestamp: deviceTimestamp,
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    String? deviceTimestamp,
  }) async {
    return await _post(
      forgotPwdUrl,
      {"action": "reset_password", "email": email, "password": password},
      deviceTimestamp: deviceTimestamp,
    );
  }
}