import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/widgets/widgets.dart';

/// Shown while the stored session is validated against `/app/auth/me`.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SmartLinkLogo(size: 72),
            const SizedBox(height: AppSpacing.lg),
            Text(AppConfig.appName, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xxxl),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
