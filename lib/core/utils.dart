import 'dart:math' as math;

String formatScore(num value) {
  final n = value.round();
  if (n < 10000) return n.toString();
  if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '${(n / 1000000).toStringAsFixed(2)}M';
}

String formatDuration(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Stable hash used for deterministic daily generation.
int hashString(String input) {
  var hash = 2166136261;
  for (final code in input.codeUnits) {
    hash ^= code;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash;
}

double clampDouble(double value, double min, double max) =>
    math.min(max, math.max(min, value));

int safeInt(Object? value, int fallback, {int min = 0, int max = 1 << 30}) {
  if (value is num && value.isFinite) {
    return clampDouble(value.toDouble(), min.toDouble(), max.toDouble()).round();
  }
  return fallback;
}

double safeDouble(Object? value, double fallback, {double min = 0, double max = 1}) {
  if (value is num && value.isFinite) {
    return clampDouble(value.toDouble(), min, max);
  }
  return fallback;
}
