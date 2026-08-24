import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/user_model.dart';
import '../../data/services/facebook_auth_service.dart';
import '../../data/services/google_auth_service.dart';
import 'auth_entry_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  void _signOut(BuildContext context) async {
    if (user.provider == 'google') {
      await GoogleAuthService.signOut();
    } else if (user.provider == 'facebook') {
      await FacebookAuthService.signOut();
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String providerLabel = user.provider == 'google'
        ? 'Google'
        : (user.provider == 'facebook' ? 'Facebook' : 'เบอร์โทรศัพท์ (OTP)');
    final Color providerColor = user.provider == 'google'
        ? AppColors.googleRed
        : (user.provider == 'facebook'
            ? AppColors.facebookBlue
            : AppColors.primary);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'PaiDuayDi',
          style: AppTypography.brandSubtitle.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _signOut(context),
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture
              if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primaryLight,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(user.photoUrl!),
                  ),
                )
              else
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'ยินดีต้อนรับสู่ PaiDuayDi!',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (user.email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGreen),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: providerColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'เข้าสู่ระบบด้วย $providerLabel สำเร็จ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
