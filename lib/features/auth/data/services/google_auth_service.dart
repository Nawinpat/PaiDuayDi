import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '936567490232-niih0a0jdpia8lh3kdtmjaklsi8k8d6t.apps.googleusercontent.com',
    clientId:
        '936567490232-niih0a0jdpia8lh3kdtmjaklsi8k8d6t.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google - returns a [GoogleSignInAccount] on success, null on cancel.
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      await _googleSignIn.signOut(); // always show account picker
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out of Google account.
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Returns the currently signed-in Google account, if any.
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
