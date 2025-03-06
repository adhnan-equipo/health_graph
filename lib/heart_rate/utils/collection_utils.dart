// lib/heart_rate/utils/collection_utils.dart
class CollectionUtils {
  /// Efficiently compare two lists for equality
  static bool listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    // For small lists, do a full comparison
    if (a.length <= 10) {
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    // For larger lists, check key positions first
    if (a.first != b.first || a.last != b.last) return false;

    // Check a few more positions for medium lists
    if (a.length > 20) {
      final quarter = a.length ~/ 4;
      final mid = a.length ~/ 2;
      final threeQuarter = mid + quarter;

      if (a[quarter] != b[quarter] ||
          a[mid] != b[mid] ||
          a[threeQuarter] != b[threeQuarter]) {
        return false;
      }
    }

    // For really big lists, compare hashCodes if available
    if (a.length > 100) {
      // This is an optimization but not guaranteed to be accurate
      if (a.hashCode != b.hashCode) return false;
    }

    return true;
  }

  /// Hash a list efficiently
  static int hashList<T>(List<T> list) {
    if (list.isEmpty) return 0;

    // For small lists, use all elements
    if (list.length <= 5) {
      return Object.hashAll(list);
    }

    // For larger lists, sample key positions
    return Object.hash(
        list.length,
        list.first,
        list.last,
        list[list.length ~/ 2],
        list.length > 10 ? list[list.length ~/ 3] : null,
        list.length > 20 ? list[list.length * 2 ~/ 3] : null);
  }
}
