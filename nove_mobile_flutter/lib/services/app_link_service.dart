import 'package:flutter/services.dart';

class AppInfo {
  final String name;
  final String packageName;

  AppInfo({required this.name, required this.packageName});
}

class AppLinkService {
  static const MethodChannel _channel = MethodChannel('com.nove.app_link');

  /// Fetches all installed launchable applications from the device
  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final List<dynamic> apps = await _channel.invokeMethod('getInstalledApps');
      return apps.map((app) => AppInfo(
        name: app['name'] as String,
        packageName: app['packageName'] as String,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Checks if the user has granted Accessibility Permissions
  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens the native Android settings to grant Accessibility Permission
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // Ignore if unavailable
    }
  }

  /// Sends the current list of linked apps to the native Android service
  static Future<void> syncLinks(Map<String, String> links) async {
    try {
      await _channel.invokeMethod('syncLinks', links);
    } catch (e) {
      // Ignore sync errors
    }
  }
}