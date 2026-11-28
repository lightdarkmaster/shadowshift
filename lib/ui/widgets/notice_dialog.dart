import 'package:material_ui/material_ui.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Tone drives the dialog colour and default icon. Failures deliberately use
/// a sad face so an insufficient-coins message reads as a setback, not a win.
enum NoticeTone { error, success, info }

extension _NoticeToneStyle on NoticeTone {
  Color get color => switch (this) {
        NoticeTone.error => AppColors.danger,
        NoticeTone.success => AppColors.cyan,
        NoticeTone.info => AppColors.violet,
      };

  IconData get icon => switch (this) {
        // A sad icon is intentional: running out of coins should feel bad.
        NoticeTone.error => Icons.sentiment_dissatisfied,
        NoticeTone.success => Icons.check_circle,
        NoticeTone.info => Icons.info_outline,
      };
}

/// Reusable replacement for bottom snackbars. Keeps notices on-screen until
/// the player acknowledges them, which also makes reward messages unmissable.
Future<void> showNoticeDialog(
  BuildContext context, {
  required String title,
  required String message,
  NoticeTone tone = NoticeTone.info,
  IconData? icon,
  IconData? badgeIcon,
  String actionLabel = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => NoticeDialog(
      title: title,
      message: message,
      tone: tone,
      icon: icon,
      badgeIcon: badgeIcon,
      actionLabel: actionLabel,
      onDismiss: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class NoticeDialog extends StatelessWidget {
  const NoticeDialog({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
    required this.icon,
    this.badgeIcon,
    required this.actionLabel,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final NoticeTone tone;
  final IconData? icon;
  final IconData? badgeIcon;
  final String actionLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = tone.color;
    final iconData = icon ?? tone.icon;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: GlassCard(
          borderColor: color.withValues(alpha: 0.55),
          padding: const EdgeInsets.all(AppLayout.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.14),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Icon(iconData, size: 34, color: color),
                  ),
                  if (badgeIcon != null)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceLight,
                          border: Border.all(color: color.withValues(alpha: 0.6)),
                        ),
                        child: Icon(badgeIcon, size: 15, color: color),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppLayout.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: AppLayout.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppLayout.lg),
              SizedBox(
                width: double.infinity,
                child: NeonButton(
                  label: actionLabel,
                  icon: Icons.check,
                  color: color,
                  compact: true,
                  onPressed: onDismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
