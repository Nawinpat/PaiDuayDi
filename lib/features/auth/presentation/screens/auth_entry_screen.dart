import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/brand_logo.dart';
import '../widgets/social_auth_button.dart';
import 'phone_entry_screen.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  void _onSocialLogin(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'เข้าสู่ระบบด้วย $provider',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onPhoneLogin(BuildContext context) {
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
              // Social Auth Buttons List
              SocialAuthButton(
                type: AuthButtonType.facebook,
                onTap: () => _onSocialLogin(context, 'Facebook'),
              ),
              SocialAuthButton(
                type: AuthButtonType.google,
                onTap: () => _onSocialLogin(context, 'Google'),
              ),
              SocialAuthButton(
                type: AuthButtonType.apple,
                onTap: () => _onSocialLogin(context, 'Apple'),
              ),
              // Divider or label
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
                onTap: () => _onPhoneLogin(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
