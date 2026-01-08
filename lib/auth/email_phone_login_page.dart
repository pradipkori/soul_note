import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/email_otp_service.dart';
import 'email_otp_verify_page.dart';

class EmailPhoneLoginPage extends StatefulWidget {
  const EmailPhoneLoginPage({super.key});

  @override
  State<EmailPhoneLoginPage> createState() => _EmailPhoneLoginPageState();
}

class _EmailPhoneLoginPageState extends State<EmailPhoneLoginPage> {
  final emailCtrl = TextEditingController();
  bool loading = false;

  Future<void> sendOtp() async {
    HapticFeedback.lightImpact();
    setState(() => loading = true);

    final email = emailCtrl.text.trim();
    final otp = EmailOtpService.generateOtp();
    final success = await EmailOtpService.sendOtp(email, otp);

    setState(() => loading = false);

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to send OTP")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailOtpVerifyPage(email: email, otp: otp, generatedOtp: '',),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.06),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Verify Email",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Enter your email",
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : sendOtp,
                    child: loading
                        ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    )
                        : const Text("Send OTP"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
