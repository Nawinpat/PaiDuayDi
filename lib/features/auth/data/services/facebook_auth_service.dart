import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user_model.dart';

class FacebookAuthService {
  /// Sign in with Facebook - returns [AppUser] on success, null on cancel
  static Future<AppUser?> signIn() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        // Fetch user profile data
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'name,email,picture.width(200)',
        );

        final String id = userData['id'] as String? ?? '';
        final String name = userData['name'] as String? ?? 'Facebook User';
        final String email = userData['email'] as String? ?? '';
        final String? photoUrl = userData['picture']?['data']?['url'] as String?;

        return AppUser(
          id: id,
          name: name,
          email: email,
          photoUrl: photoUrl,
          provider: 'facebook',
        );
      } else if (result.status == LoginStatus.cancelled) {
        return null;
      } else {
        throw Exception(result.message ?? 'เข้าสู่ระบบด้วย Facebook ไม่สำเร็จ');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from Facebook
  static Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
  }
}
