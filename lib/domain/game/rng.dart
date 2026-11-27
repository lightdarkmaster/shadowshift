/// Small deterministic xorshift generator. Identical seeds always produce
/// identical runs, which powers the offline daily challenge.
class SeededRandom {
  SeededRandom(int seed) : _state = seed == 0 ? 0x9E3779B9 : seed & 0xFFFFFFFF;

  int _state;

  int nextInt(int max) {
    if (max <= 1) return 0;
    return next() % max;
  }

  double nextDouble() => next() / 4294967296.0;

  bool nextBool() => next().isOdd;

  double range(double min, double max) => min + nextDouble() * (max - min);

  int next() {
    var x = _state;
    x ^= x << 13;
    x &= 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= x << 5;
    x &= 0xFFFFFFFF;
    _state = x;
    return x;
  }
}
