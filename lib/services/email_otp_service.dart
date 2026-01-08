import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailOtpService {
  // 🔐 EmailJS credentials
  static const String serviceId = 'service_53s5j8a';
  static const String templateId = 'template_zoi2xyu';
  static const String publicKey = 'szjDdMQQqAWRqWsWo';

  // 🧠 TEMP OTP STORE
  static String? _storedOtp;
  static DateTime? _expiryTime;

  // 🔢 Generate OTP
  static String generateOtp() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    _storedOtp = otp;
    _expiryTime = DateTime.now().add(const Duration(minutes: 5));

    return otp;
  }

  // 📩 Send OTP
  static Future<bool> sendOtp(String email, String otp) async {
    final otp = generateOtp();

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'email': email,
          'otp': otp,
        },
      }),
    );

    return response.statusCode == 200;
  }

  // ✅ VERIFY OTP
  static bool verifyOtp(String inputOtp) {
    if (_storedOtp == null || _expiryTime == null) return false;

    if (DateTime.now().isAfter(_expiryTime!)) return false;

    return inputOtp == _storedOtp;
  }

  // 🧹 CLEAR OTP AFTER SUCCESS
  static void clearOtp() {
    _storedOtp = null;
    _expiryTime = null;
  }
}
