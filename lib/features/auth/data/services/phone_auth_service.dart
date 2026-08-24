import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class PhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;

  /// Send OTP to the given phone number.
  /// [onCodeSent] is called when Firebase sends the SMS.
  /// [onError] is called if there is an error.
  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verified on Android (rare case)
        onAutoVerified?.call(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        String message;
        switch (e.code) {
          case 'invalid-phone-number':
            message = 'หมายเลขโทรศัพท์ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง';
            break;
          case 'too-many-requests':
            message = 'ส่ง OTP บ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่';
            break;
          case 'quota-exceeded':
            message = 'เกินโควต้าการส่ง SMS กรุณาลองใหม่ภายหลัง';
            break;
          default:
            message = 'เกิดข้อผิดพลาด: ${e.message ?? e.code}';
        }
        onError(message);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Verify the OTP code entered by the user.
  static Future<AppUser?> verifyOtp({
    required String smsCode,
    String? verificationId,
  }) async {
    final vId = verificationId ?? _verificationId;
    if (vId == null) {
      throw Exception('ไม่พบ Verification ID กรุณาขอรหัส OTP ใหม่อีกครั้ง');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: vId,
      smsCode: smsCode,
    );

    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('เข้าสู่ระบบไม่สำเร็จ');

      return AppUser(
        id: user.uid,
        name: user.displayName ?? user.phoneNumber ?? 'ผู้ใช้งาน',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        provider: 'phone',
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('รหัส OTP ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง');
        case 'session-expired':
          throw Exception('รหัส OTP หมดอายุแล้ว กรุณาขอรหัสใหม่');
        default:
          throw Exception('เกิดข้อผิดพลาด: ${e.message ?? e.code}');
      }
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
