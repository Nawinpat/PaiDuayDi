import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/user_model.dart';
import '../../data/services/facebook_auth_service.dart';
import '../../data/services/google_auth_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/social_auth_button.dart';
import 'phone_entry_screen.dart';
import 'home_screen.dart';

class AuthEntryScreen extends StatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;

  void _onSocialLogin(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'เร็วๆ นี้: เข้าสู่ระบบด้วย $provider',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onFacebookLogin() async {
    setState(() => _isFacebookLoading = true);
    try {
      final user = await FacebookAuthService.signIn();
      if (!mounted) return;
      if (user != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, _) => HomeScreen(user: user),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เข้าสู่ระบบ Facebook ไม่สำเร็จ: ${e.toString()}',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

  Future<void> _onGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final account = await GoogleAuthService.signIn();
      if (!mounted) return;
      if (account != null) {
        final user = AppUser(
          id: account.id,
          name: account.displayName ?? 'Google User',
          email: account.email,
          photoUrl: account.photoUrl,
          provider: 'google',
        );
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, _) => HomeScreen(user: user),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เข้าสู่ระบบ Google ไม่สำเร็จ: ${e.toString()}',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _onPhoneLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PhoneEntryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Main Illustration / Brand Logo
              const BrandLogo(
                size: 110,
                showText: false,
              ),
              const SizedBox(height: 16),
              Text(
                'PaiDuayDi',
                style: AppTypography.brandSubtitle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'แชร์เส้นทาง แชร์ค่าเดินทาง ปลอดภัยทุกทริป',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const Spacer(flex: 2),
              // Facebook Auth Button with loading state
              _isFacebookLoading
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.facebookBlue),
                          ),
                        ),
                      ),
                    )
                  : SocialAuthButton(
                      type: AuthButtonType.facebook,
                      onTap: _onFacebookLogin,
                    ),
              // Google Sign-In with loading state
              _isGoogleLoading
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ),
                    )
                  : SocialAuthButton(
                      type: AuthButtonType.google,
                      onTap: _onGoogleLogin,
                    ),
              SocialAuthButton(
                type: AuthButtonType.apple,
                onTap: () => _onSocialLogin(context, 'Apple'),
              ),
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'หรือ',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                  ],
                ),
              ),
              SocialAuthButton(
                type: AuthButtonType.phone,
                onTap: _onPhoneLogin,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
