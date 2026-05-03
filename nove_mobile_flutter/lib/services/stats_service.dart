import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static const _kStreakKey = 'streak_count';
  static const _kWordsTodayKey = 'words_today';
  static const _kLastActiveDateKey = 'last_active_date';
  static const _kDailyGoalKey = 'daily_word_goal';

  static Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDailyReset(prefs);

    return {
      'streak': prefs.getInt(_kStreakKey) ?? 0,
      'wordsToday': prefs.getInt(_kWordsTodayKey) ?? 0,
      'dailyGoal': prefs.getInt(_kDailyGoalKey) ?? 500,
    };
  }

  static Future<void> addWords(int count) async {
    if (count <= 0) return;
    
    final prefs = await SharedPreferences.getInstance();
    await _checkDailyReset(prefs);

    final wordsToday = (prefs.getInt(_kWordsTodayKey) ?? 0) + count;
    final dailyGoal = prefs.getInt(_kDailyGoalKey) ?? 500;
    var streak = prefs.getInt(_kStreakKey) ?? 0;

    await prefs.setInt(_kWordsTodayKey, wordsToday);

    // If goal is met today and we haven't already counted it towards streak
    final wasGoalMetBefore = (wordsToday - count) >= dailyGoal;
    final isGoalMetNow = wordsToday >= dailyGoal;

    if (isGoalMetNow && !wasGoalMetBefore) {
      streak += 1;
      await prefs.setInt(_kStreakKey, streak);
    }
  }

  static Future<void> updateDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDailyGoalKey, goal);
  }

  static Future<void> _checkDailyReset(SharedPreferences prefs) async {
    final lastActiveStr = prefs.getString(_kLastActiveDateKey);
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (lastActiveStr == null) {
      // First time using stats
      await prefs.setString(_kLastActiveDateKey, todayStr);
      return;
    }

    if (lastActiveStr != todayStr) {
      // It's a new day!
      final lastActiveDate = DateTime.parse(lastActiveStr);
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day))
          .inDays;

      if (difference > 1) {
        // Streak broken
        await prefs.setInt(_kStreakKey, 0);
      }

      await prefs.setInt(_kWordsTodayKey, 0);
      await prefs.setString(_kLastActiveDateKey, todayStr);
    }
  }
}
