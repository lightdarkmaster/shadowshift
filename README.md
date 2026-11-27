# SHADOW SHIFT

A fast, fully offline, neon-noir endless runner for Android. Phase between **Light** and **Shadow** to dodge procedurally generated obstacles, collect energy orbs, build combos, and unlock every runner, skin, core, and effect through gameplay.

No account, no server, no ads, no analytics, and no network permission. All music and sound effects are synthesized locally on first launch.

## Features

- **Four modes**
  - **Classic** — endless survival with a steadily rising speed/difficulty curve.
  - **Time Attack** — a 60-second score sprint.
  - **Challenges** — six sequential objectives with one-time coin/XP rewards.
  - **Daily Challenge** — a deterministic run and three missions seeded from the local date.
- **Core loop** — tap or swipe to phase, collect orbs only in their matching dimension, dodge obstacles, and chain dodges for up to an **x8** multiplier.
- **Power-ups** — Phase Shield, Orb Magnet, Time Slow, and Double Score.
- **Progression** — XP/levels, coins, 12 achievements, daily reward streaks, daily missions, persistent statistics, and best scores per mode.
- **Shop** — five characters with distinct perks, four skins, four phase effects, and four passive cores. Everything is purchasable with coins earned in-game.
- **Accessibility** — independent music/SFX volume, haptics toggle, reduced motion, screen shake toggle, and hint toggle. The game remains completely playable with sound disabled.
- **Polish** — Flame-driven frame loop, pure-Dart deterministic simulation, custom neon canvas rendering, glassmorphic UI, animated page transitions, lifecycle-aware pause, and corrupted-save recovery.

## Controls

| Input | Action |
| --- | --- |
| Tap anywhere / swipe vertically | Switch between Light and Shadow |
| Hold (with **SPECTRE** equipped) | Chrono Focus — slow time while energy lasts |
| Pause button | Pause, resume, restart, or quit |
| Device backgrounded | Automatically pauses the run |

## Screens

1. Splash
2. Main menu
3. Mode selection
4. Challenge selection
5. Gameplay
6. Game over / run report
7. Character selection
8. Shop
9. Achievements
10. Missions
11. Statistics
12. Settings

## Architecture

- `lib/core/` — tuning constants, colors, theme, and shared utilities.
- `lib/data/` — validated JSON models and a `SharedPreferences` repository.
- `lib/domain/game/` — pure-Dart engine, difficulty curve, RNG, scoring, and entities.
- `lib/domain/progression/` — shop catalog, challenges, achievements, and missions.
- `lib/domain/services/` — run rewards, launches, deterministic daily generation, and local audio synthesis.
- `lib/state/` — lightweight Riverpod notifiers for profile and settings.
- `lib/game/` — Flame lifecycle bridge and the single-pass `CustomPainter` renderer.
- `lib/ui/` — 12 screens and reusable design widgets.

The simulation runs in virtual world units (`1000` wide), so obstacle timing and fairness are identical across portrait screen sizes. Rendering is a single canvas pass with capped particles and clamped delta time for stable 60fps play.

## Getting started

Requires a recent Flutter SDK with the Android toolchain installed.

```bash
flutter pub get
flutter run
```

To verify the project:

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

For a release build on a machine with a configured signing identity, add `--split-per-abi` if desired. The release manifest declares no permissions; only the debug/profile manifests declare `INTERNET` for Flutter tooling.

## Offline guarantee

- No HTTP clients, remote assets, social SDKs, ads, or cloud saves.
- Daily content uses the device clock and a local hash; it works in airplane mode.
- Audio WAV files are generated into the app's documents directory on first launch.
- Progress is stored locally in `SharedPreferences` keys `shadowshift.profile.v1` and `shadowshift.settings.v1`. Malformed saves fall back to a valid default profile.
- No permissions beyond those required by the Flutter runtime are declared by the app.

## Tests

`flutter test` covers:

- Dimension switching, pause/restart guards, collision, shield, orbs, power-ups, combo scoring, and all four mode objectives.
- Deterministic seeds and a 90-second reactive-player fairness simulation.
- Daily challenge/mission determinism, reward claims, sequential unlocks, purchase rules, level curve, and save validation.
- Repository round-trips, corrupted data recovery, and stale daily-state resets.
- Widget smoke tests for splash → menu → mode selection → challenge selection navigation.
