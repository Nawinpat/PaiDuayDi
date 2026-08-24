import 'dart:math';
import '../models/user_model.dart';

class OtpAuthService {
  static String? _currentOtp;
  static String? _activePhoneNumber;

  /// Generate and send a 6-digit OTP code to the given phone number
  static Future<String> sendOtp(String phoneNumber) async {
    // Generate a random 6-digit OTP (e.g. 842193) or use 123456
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    _currentOtp = otp;
    _activePhoneNumber = phoneNumber;

    // Simulate network delay for SMS dispatch
    await Future.delayed(const Duration(milliseconds: 600));
    return otp;
  }

  /// Verify the entered OTP code
  static Future<AppUser?> verifyOtp({
    required String phoneNumber,
    required String enteredOtp,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Accept either generated OTP or demo OTP "123456"
    if (enteredOtp == _currentOtp || enteredOtp == '123456') {
      return AppUser(
        id: phoneNumber.replaceAll(RegExp(r'\D'), ''),
        name: 'ผู้ใช้งาน $phoneNumber',
        email: '',
        photoUrl: null,
        provider: 'phone',
      );
    } else {
      throw Exception('รหัส OTP ไม่ถูกต้อง กรุณากรอกรหัสที่ได้รับใหม่อีกครั้ง');
    }
  }

  /// Resend OTP
  static Future<String> resendOtp() async {
    if (_activePhoneNumber != null) {
      return sendOtp(_activePhoneNumber!);
    }
    return sendOtp('0812345678');
  }
}
