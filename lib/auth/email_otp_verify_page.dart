import 'package:flutter/material.dart';
import 'package:soul_note/auth/login_success_page.dart';
import '../services/email_otp_service.dart';
import '../home_page.dart';

class EmailOtpVerifyPage extends StatefulWidget {
  final String email;

  const EmailOtpVerifyPage({
    super.key,
    required this.email, required String otp, required String generatedOtp,
  });

  @override
  State<EmailOtpVerifyPage> createState() => _EmailOtpVerifyPageState();
}

class _EmailOtpVerifyPageState extends State<EmailOtpVerifyPage> {
  final otpCtrl = TextEditingController();

  void verify() {
    final success = EmailOtpService.verifyOtp(
      otpCtrl.text.trim(),
    );

    if (success) {
      EmailOtpService.clearOtp();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginSuccessPage()),
            (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid or expired OTP")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "OTP sent to ${widget.email}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter OTP",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: verify,
              child: const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
