/// Common Extension Methods
///
/// Utility extensions for common Dart types.
library;

/// String extensions
extension StringExtensions on String {
  /// Capitalizes the first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes each word
  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Check if string is a valid email (supports + aliases like user+tag@example.com)
  bool get isValidEmail {
    return RegExp(r'^[\w-\.+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Returns null if empty, otherwise returns the string
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// Nullable String extensions
extension NullableStringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns the string or a default value
  String orDefault(String defaultValue) => isNullOrEmpty ? defaultValue : this!;
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Returns true if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// End of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Format as ISO date string (YYYY-MM-DD)
  String toIsoDateString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Returns first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Returns last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Returns element at index or null
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}

/// Map extensions
extension MapExtensions<K, V> on Map<K, V> {
  /// Get value or default
  V getOrDefault(K key, V defaultValue) => this[key] ?? defaultValue;
}

/// Duration extensions
extension DurationExtensions on Duration {
  /// Format as MM:SS
  String toMinutesSeconds() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Format as HH:MM:SS
  String toHoursMinutesSeconds() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
