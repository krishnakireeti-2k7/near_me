// file: lib/services/local_interests_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the LocalInterestsService
final localInterestsServiceProvider = Provider(
  (ref) => LocalInterestsService(),
);

class LocalInterestsService {
  static const String _dailyInterestsCountKey = 'dailyInterestsCount';
  static const String _lastResetDateKey = 'lastInterestsResetDate';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Get the current daily interests count
  // This method will handle the daily reset logic
  Future<int> getDailyInterestsCount() async {
    final prefs = await _getPrefs();
    final int count = prefs.getInt(_dailyInterestsCountKey) ?? 0;
    final String? lastResetDateString = prefs.getString(_lastResetDateKey);

    if (lastResetDateString != null) {
      final DateTime lastResetDate = DateTime.parse(lastResetDateString);
      final DateTime now = DateTime.now();
      // Check if the last reset was on a different day than today
      if (lastResetDate.year != now.year ||
          lastResetDate.month != now.month ||
          lastResetDate.day != now.day) {
        // It's a new day, reset the count
        await _resetDailyInterestsCount();
        return 0; // Return 0 as it's a new day and count has been reset
      }
    } else {
      // If no last reset date is found, assume it's the first run or a new day
      await _resetDailyInterestsCount(); // Initialize
      return 0;
    }
    return count;
  }

  // Increment the daily interests count
  Future<void> incrementDailyInterestsCount() async {
    final prefs = await _getPrefs();
    int currentCount =
        await getDailyInterestsCount(); // Get the count, which also handles potential reset
    currentCount++;
    await prefs.setInt(_dailyInterestsCountKey, currentCount);
    // Update the last reset date to today
    await prefs.setString(
      _lastResetDateKey,
      DateTime.now().toIso8601String(),
    ); // Store current date as string
  }

  // Resets the daily interests count and updates the reset date to today
  Future<void> _resetDailyInterestsCount() async {
    final prefs = await _getPrefs();
    await prefs.setInt(_dailyInterestsCountKey, 0);
    await prefs.setString(_lastResetDateKey, DateTime.now().toIso8601String());
    print('Daily interests count reset for a new day.'); // For debugging
  }

  // Optional: For manually setting a count (e.g., for testing)
  Future<void> setDailyInterestsCount(int count) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_dailyInterestsCountKey, count);
    await prefs.setString(
      _lastResetDateKey,
      DateTime.now().toIso8601String(),
    ); // Update date if count is set
  }
}
