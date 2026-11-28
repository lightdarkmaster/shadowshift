import 'package:material_ui/material_ui.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// About panel opened by tapping the logo on the home screen.
class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppLayout.lg,
        AppLayout.lg,
        AppLayout.lg,
        0,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppLayout.lg,
        AppLayout.md,
        AppLayout.lg,
        AppLayout.sm,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppLayout.md,
        0,
        AppLayout.md,
        AppLayout.md,
      ),
      title: Column(
        children: [
          Image.asset(
            'assets/images/shadowshift_neon_logo.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppLayout.sm),
          GradientLabel(AppStrings.appName, fontSize: 20, letterSpacing: 3),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2.5,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: AppLayout.md),
            const Text(
              'A fast, offline cyberpunk arcade runner. Phase through obstacles, '
              'collect orbs and chase a new personal best anywhere — no account '
              'or connection required.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: AppLayout.md),
            const _AboutFact(
              icon: Icons.wifi_off_rounded,
              label: 'Fully offline — play with no signal',
              color: AppColors.cyan,
            ),
            const SizedBox(height: AppLayout.sm),
            const _AboutFact(
              icon: Icons.emoji_events_outlined,
              label: 'Characters, missions and daily challenges',
              color: AppColors.violet,
            ),
            const SizedBox(height: AppLayout.sm),
            const _AboutFact(
              icon: Icons.save_outlined,
              label: 'Progress saved locally on this device',
              color: AppColors.gold,
            ),
            const SizedBox(height: AppLayout.md),
            Text(
              'v${AppStrings.version} · Built by lightdarkmaster',
              textAlign: TextAlign.center,
              style: AppTextStyles.micro.copyWith(letterSpacing: 1.2),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CLOSE',
            style: TextStyle(
              color: AppColors.cyan,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutFact extends StatelessWidget {
  const _AboutFact({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: AppLayout.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}
