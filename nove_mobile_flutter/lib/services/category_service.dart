import 'package:shared_preferences/shared_preferences.dart';

/// Built-in categories that always appear in the category list.
const kBuiltInCategories = ['Work', 'Ideas', 'Personal', 'Urgent'];

/// SharedPreferences key for user-created categories.
const _kCustomCategoriesKey = 'custom_categories';

class CategoryService {
  /// Returns all categories: built-ins + any user-created ones.
  static Future<List<String>> loadAllCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList(_kCustomCategoriesKey) ?? [];
    return [...kBuiltInCategories, ...custom];
  }

  /// Persists a new custom category (no-op if it already exists).
  static Future<void> saveCustomCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kCustomCategoriesKey) ?? [];
    if (!existing.contains(category)) {
      existing.add(category);
      await prefs.setStringList(_kCustomCategoriesKey, existing);
    }
  }

  /// Removes a custom category (has no effect on built-in categories).
  static Future<void> removeCustomCategory(String category) async {
    if (kBuiltInCategories.contains(category)) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kCustomCategoriesKey) ?? [];
    existing.remove(category);
    await prefs.setStringList(_kCustomCategoriesKey, existing);
  }
}
