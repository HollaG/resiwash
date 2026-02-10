extension StringExtensions on String {
  /// Capitalizes the first character of the string
  ///
  /// Example:
  /// ```dart
  /// "washer".capitalize() // Returns "Washer"
  /// "dryer".capitalize()  // Returns "Dryer"
  /// "".capitalize()       // Returns ""
  /// ```
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
