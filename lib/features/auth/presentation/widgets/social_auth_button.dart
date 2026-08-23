import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum AuthButtonType { facebook, google, apple, phone }

class SocialAuthButton extends StatelessWidget {
  final AuthButtonType type;
  final VoidCallback onTap;

  const SocialAuthButton({
    super.key,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Widget icon;

    switch (type) {
      case AuthButtonType.facebook:
        text = 'ดำเนินการต่อด้วย Facebook';
        icon = Image.asset(
          'assets/icons/facebook_icon.png',
          width: 26,
          height: 26,
          errorBuilder: (_, __, ___) => Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.facebookBlue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'f',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
        break;
      case AuthButtonType.google:
        text = 'ดำเนินการต่อด้วย Google';
        icon = Image.asset(
          'assets/icons/google_logo.png',
          width: 24,
          height: 24,
        );
        break;
      case AuthButtonType.apple:
        text = 'ดำเนินการต่อด้วย Apple';
        icon = const Icon(
          Icons.apple,
          color: Colors.black,
          size: 26,
        );
        break;
      case AuthButtonType.phone:
        text = 'ดำเนินการต่อด้วยเบอร์โทรศัพท์';
        icon = Image.asset(
          'assets/icons/phone_icon.png',
          width: 22,
          height: 22,
          color: Colors.black87,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.phone,
            color: Colors.black87,
            size: 22,
          ),
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: icon,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.heading3.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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
