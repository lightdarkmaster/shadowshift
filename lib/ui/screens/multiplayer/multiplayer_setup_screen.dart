import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_gameplay_screen.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Configures a local hot-seat match before handing the record to gameplay.
class MultiplayerSetupScreen extends ConsumerStatefulWidget {
  const MultiplayerSetupScreen({super.key});

  @override
  ConsumerState<MultiplayerSetupScreen> createState() =>
      _MultiplayerSetupScreenState();
}

class _MultiplayerSetupScreenState extends ConsumerState<MultiplayerSetupScreen> {
  static const int _maxPlayers = 6;
  static const int _maxRounds = 5;

  final List<TextEditingController> _names = List.generate(
    _maxPlayers,
    (index) => TextEditingController(text: 'Player ${index + 1}'),
  );
  int _playerCount = 2;
  int _rounds = 1;
  Set<int> _invalid = const <int>{};
  String? _error;

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startMatch() {
    FocusScope.of(context).unfocus();
    final invalid = <int>{};
    final names = <String>[];
    for (var i = 0; i < _playerCount; i++) {
      final name = _names[i].text.trim();
      if (name.isEmpty) {
        invalid.add(i);
      } else {
        names.add(name);
      }
    }
    setState(() {
      _invalid = invalid;
      _error = invalid.isEmpty ? null : 'Every player needs a name.';
    });
    if (invalid.isNotEmpty) return;

    final record = ref
        .read(multiplayerProfileProvider.notifier)
        .startMatch(names, _rounds);
    if (!mounted) return;
    pushScreen(context, MultiplayerGameplayScreen(match: record));
  }

  @override
  Widget build(BuildContext context) {
    final totalTurns = _playerCount * _rounds;
    return AppScaffold(
      title: 'NEW MATCH',
      subtitle: 'Set up a local hot-seat game',
      showCoins: false,
      actions: const [
        StatChip(icon: Icons.phonelink, value: 'LOCAL', color: AppColors.violet),
      ],
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    'PLAYERS',
                    trailing: Text('$_playerCount / $_maxPlayers',
                        style: AppTextStyles.caption),
                  ),
                  const SizedBox(height: AppLayout.md),
                  Wrap(
                    spacing: AppLayout.sm,
                    runSpacing: AppLayout.sm,
                    children: [
                      for (var count = 2; count <= _maxPlayers; count++)
                        _OptionChip(
                          label: '$count',
                          selected: _playerCount == count,
                          color: AppColors.violet,
                          onTap: () => setState(() {
                            _playerCount = count;
                            _invalid = const <int>{};
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.lg),
                  for (var i = 0; i < _playerCount; i++) ...[
                    if (i > 0) const SizedBox(height: AppLayout.sm),
                    TextField(
                      controller: _names[i],
                      maxLength: 16,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Player ${i + 1}',
                        labelStyle: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(Icons.person_outline,
                            size: 18, color: AppColors.violet),
                        counterText: '',
                        errorText: _invalid.contains(i) ? 'Name required' : null,
                        errorStyle: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLight.withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          borderSide: BorderSide(
                            color: AppColors.violet.withValues(alpha: 0.25),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          borderSide: BorderSide(
                            color: AppColors.violet.withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          borderSide: const BorderSide(color: AppColors.violet),
                        ),
                      ),
                      onChanged: (_) {
                        if (_error == null) return;
                        setState(() {
                          _invalid = const <int>{};
                          _error = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    'ROUNDS',
                    trailing: Text('$_rounds of $_maxRounds',
                        style: AppTextStyles.caption),
                  ),
                  const SizedBox(height: AppLayout.md),
                  Wrap(
                    spacing: AppLayout.sm,
                    runSpacing: AppLayout.sm,
                    children: [
                      for (var value = 1; value <= _maxRounds; value++)
                        _OptionChip(
                          label: '$value',
                          selected: _rounds == value,
                          color: AppColors.cyan,
                          onTap: () => setState(() => _rounds = value),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              borderColor: AppColors.gold.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('MATCH SUMMARY'),
                  const SizedBox(height: AppLayout.md),
                  for (var i = 0; i < _playerCount; i++) ...[
                    if (i > 0) const SizedBox(height: AppLayout.sm),
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.violet.withValues(alpha: 0.16),
                            borderRadius:
                                BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: AppColors.violet,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppLayout.sm),
                        Expanded(
                          child: Text(
                            _names[i].text.trim().isEmpty
                                ? 'Player ${i + 1}'
                                : _names[i].text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppLayout.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppLayout.md),
                  Wrap(
                    spacing: AppLayout.sm,
                    runSpacing: AppLayout.sm,
                    children: [
                      StatChip(
                        icon: Icons.repeat,
                        value: '$_rounds ${_rounds == 1 ? 'round' : 'rounds'}',
                        color: AppColors.cyan,
                      ),
                      StatChip(
                        icon: Icons.people_outline,
                        value: '$_playerCount players',
                        color: AppColors.violet,
                      ),
                      StatChip(
                        icon: Icons.touch_app,
                        value: '$totalTurns turns',
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppLayout.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.md,
                  vertical: AppLayout.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 15, color: AppColors.danger),
                    const SizedBox(width: AppLayout.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppLayout.sectionGap),
            NeonButton(
              label: 'START GAME',
              icon: Icons.play_arrow_rounded,
              onPressed: _startMatch,
            ),
            const SizedBox(height: AppLayout.md),
            const Text(
              'Scores, rewards and stats stay on this device. '
              'Pass the device to each player in turn.',
              textAlign: TextAlign.center,
              style: AppTextStyles.micro,
            ),
            const SizedBox(height: AppLayout.lg),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.18) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: selected ? color : color.withValues(alpha: 0.24),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.md,
              vertical: AppLayout.sm,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
