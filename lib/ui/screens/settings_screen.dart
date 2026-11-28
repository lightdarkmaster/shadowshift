import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/notice_dialog.dart';

/// Typing this exact word is required before saved progress can be erased.
const String resetConfirmationKeyword = 'Shadowshift';

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
                  const SectionTitle(
                    'AUDIO',
                    subtitle: 'Music and effects are generated offline',
                  ),
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
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      label: 'RESET ALL PROGRESS',
                      icon: Icons.delete_forever,
                      secondary: true,
                      color: AppColors.danger,
                      onPressed: () => _confirmReset(context, ref),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${AppStrings.appName} v${AppStrings.version} · 100% OFFLINE',
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ResetProgressDialog(
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          ref.read(profileProvider.notifier).resetProgress();
          Navigator.of(dialogContext).pop();
          AudioService.instance.ui();
          showNoticeDialog(
            context,
            title: 'PROGRESS RESET',
            message: 'Progress reset. A fresh run awaits.',
            tone: NoticeTone.info,
            icon: Icons.restart_alt,
          );
        },
      ),
    );
  }
}

/// Destructive action guard: the reset button stays disabled until the exact
/// keyword is entered, so an accidental tap can never wipe the save.
class _ResetProgressDialog extends StatefulWidget {
  const _ResetProgressDialog({required this.onConfirm, required this.onCancel});

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  State<_ResetProgressDialog> createState() => _ResetProgressDialogState();
}

class _ResetProgressDialogState extends State<_ResetProgressDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _attempted = false;

  bool get _keywordMatches => _controller.text == resetConfirmationKeyword;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _attempted = true);
    if (_keywordMatches) widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final showError = _attempted && !_keywordMatches;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.45)),
      ),
      title: const Text(
        'RESET PROGRESS?',
        style: TextStyle(
          color: AppColors.danger,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes coins, unlocks, achievements, missions and high scores '
            'from this device. This cannot be undone.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          const Text(
            'TYPE "$resetConfirmationKeyword" TO CONFIRM',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: resetConfirmationKeyword,
              border: const UnderlineInputBorder(),
              errorText: showError ? 'Exact keyword required' : null,
              errorStyle: const TextStyle(
                color: AppColors.danger,
                fontSize: 10,
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('CANCEL')),
        NeonButton(
          label: 'DELETE PROGRESS',
          icon: Icons.delete_forever,
          color: AppColors.danger,
          secondary: true,
          compact: true,
          enabled: _keywordMatches,
          onPressed: _submit,
        ),
      ],
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                Slider(
                  value: value,
                  onChanged: onChanged,
                  activeColor: color,
                  inactiveColor: AppColors.surfaceLight,
                ),
              ],
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
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
