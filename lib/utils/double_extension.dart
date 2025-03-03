/// Enhanced extension for doubles with performance optimizations
extension DoubleExtension on double {
  /// Calculate square root efficiently
  double sqrt() {
    if (this <= 0) return 0;
    double x = this;
    double y = 1;
    double epsilon = 0.000001;
    while ((x - y) > epsilon) {
      x = (x + y) / 2;
      y = this / x;
    }
    return x;
  }
  
  /// Rounds the double value and returns as integer
  int get roundToInt => (this + 0.5).floor();
  
  /// Efficiently check if a value is near another value within a threshold
  bool isNear(double other, [double threshold = 0.001]) {
    return (this - other).abs() < threshold;
  }
  
  /// Efficiently clamps a value between a minimum and maximum
  double clampValue(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
  
  /// Round to specified decimal places for display formatting
  double roundToDecimal(int places) {
    if (places <= 0) return (this + 0.5).floorToDouble();
    final mod = 10.0 * places;
    return ((this * mod) + 0.5).floorToDouble() / mod;
  }
}
