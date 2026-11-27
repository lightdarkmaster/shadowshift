import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return AppScaffold(
      title: 'SETTINGS',
      subtitle: 'Saved locally on this device',
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('AUDIO', subtitle: 'Music and effects are generated offline'),
                  const SizedBox(height: 16),
                  _SliderTile(
                    icon: Icons.music_note,
                    label: 'MUSIC VOLUME',
                    value: settings.musicVolume,
                    color: AppColors.violet,
                    onChanged: notifier.setMusicVolume,
                  ),
                  _SliderTile(
                    icon: Icons.volume_up,
                    label: 'SOUND EFFECTS',
                    value: settings.sfxVolume,
                    color: AppColors.cyan,
                    onChanged: notifier.setSfxVolume,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('GAMEPLAY & ACCESSIBILITY'),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.vibration,
                    label: 'HAPTIC FEEDBACK',
                    subtitle: 'Vibrate on shifts and impacts',
                    value: settings.haptics,
                    onChanged: (value) {
                      notifier.setHaptics(value);
                      if (value) haptic();
                    },
                  ),
                  _ToggleTile(
                    icon: Icons.screen_rotation,
                    label: 'SCREEN SHAKE',
                    subtitle: 'Impact camera feedback',
                    value: settings.screenShake,
                    onChanged: notifier.setScreenShake,
                  ),
                  _ToggleTile(
                    icon: Icons.blur_off,
                    label: 'REDUCED MOTION',
                    subtitle: 'Disables pulses, shake and drifting stars',
                    value: settings.reducedMotion,
                    onChanged: notifier.setReducedMotion,
                  ),
                  _ToggleTile(
                    icon: Icons.help_outline,
                    label: 'SHOW HINTS',
                    subtitle: 'Display control hints before a run',
                    value: settings.showHints,
                    onChanged: notifier.setShowHints,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('DATA'),
                  const SizedBox(height: 10),
                  const Text(
                    'Progress lives only in local storage. No account, no network, no ads, '
                    'and no personal information is collected.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  NeonButton(
                    label: 'RESET ALL PROGRESS',
                    icon: Icons.delete_forever,
                    secondary: true,
                    color: AppColors.danger,
                    onPressed: () => _confirmReset(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('SHADOW SHIFT v1.0 · 100% OFFLINE',
                style: TextStyle(
                    fontSize: 10, letterSpacing: 1.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('RESET PROGRESS?'),
        content: const Text(
          'This permanently deletes coins, unlocks, achievements, missions and high scores '
          'from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(profileProvider.notifier).resetProgress();
              Navigator.of(dialogContext).pop();
              AudioService.instance.ui();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress reset. A fresh run awaits.'),
                  backgroundColor: AppColors.surfaceLight,
                ),
              );
            },
            child: const Text('RESET', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                Slider(
                  value: value,
                  onChanged: onChanged,
                  activeColor: color,
                  inactiveColor: AppColors.surfaceLight,
                ),
              ],
            ),
          ),
          Text('${(value * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              onChanged(v);
              AudioService.instance.ui();
            },
            activeThumbColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }
}
