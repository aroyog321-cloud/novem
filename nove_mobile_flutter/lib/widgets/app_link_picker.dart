import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< HEAD
import '../services/app_link_service.dart';
import '../theme/tokens.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
=======
import 'dart:io'; // FIX: needed for Platform.isAndroid
import '../services/app_link_service.dart';
import '../theme/tokens.dart';
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f

void showAppLinkPicker({
  required BuildContext context,
  required Function(AppInfo) onAppSelected,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _AppLinkPickerSheet(onAppSelected: onAppSelected),
  );
}

class _AppLinkPickerSheet extends StatefulWidget {
  final Function(AppInfo) onAppSelected;
  const _AppLinkPickerSheet({required this.onAppSelected});

  @override
  State<_AppLinkPickerSheet> createState() => _AppLinkPickerSheetState();
}

<<<<<<< HEAD
class _AppLinkPickerSheetState extends State<_AppLinkPickerSheet> with WidgetsBindingObserver {
  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  bool _needsAccessibilityPermission = false;
  bool _needsOverlayPermission = false;
=======
class _AppLinkPickerSheetState extends State<_AppLinkPickerSheet> {
  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  bool _needsPermission = false;
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    WidgetsBinding.instance.addObserver(this);
    _loadApps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_needsAccessibilityPermission || _needsOverlayPermission) {
        _loadApps();
      }
    }
  }

  Future<void> _loadApps() async {
    final hasAccessibilityPerm = await AppLinkService.isAccessibilityEnabled();
    final hasOverlayPerm = await FlutterOverlayWindow.isPermissionGranted();

    if (!hasAccessibilityPerm || !hasOverlayPerm) {
      setState(() {
        _needsAccessibilityPermission = !hasAccessibilityPerm;
        _needsOverlayPermission = !hasOverlayPerm;
=======
    _loadApps();
  }

  Future<void> _loadApps() async {
    // FIX: App linking (accessibility service) is Android-only.
    // On iOS/Web, show the permission screen so the user understands
    // why this feature isn't available, instead of hanging in a
    // loading spinner or crashing with MissingPluginException.
    if (!Platform.isAndroid) {
      setState(() {
        _needsPermission = true;
        _isLoading = false;
      });
      return;
    }

    final hasPerm = await AppLinkService.isAccessibilityEnabled();
    if (!hasPerm) {
      setState(() {
        _needsPermission = true;
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
        _isLoading = false;
      });
      return;
    }

    final apps = await AppLinkService.getInstalledApps();
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      _apps = apps;
      _filteredApps = apps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
<<<<<<< HEAD
    
=======

>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: NoveColors.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: NoveColors.warmGray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Link to App',
              style: GoogleFonts.lora(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NoveColors.primaryText(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'This note will automatically pop up when you open the selected application.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: NoveColors.secondaryText(context),
              ),
            ),
          ),
<<<<<<< HEAD
          
          if (_needsAccessibilityPermission || _needsOverlayPermission) ...[
=======

          if (_needsPermission) ...[
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
<<<<<<< HEAD
                      Icon(Icons.admin_panel_settings, size: 48, color: NoveColors.accent(context)),
                      const SizedBox(height: 16),
                      Text(
                        'Permissions Required',
                        style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'NOVE needs the following permissions to detect when you launch an app and to display the sticky note over it.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(color: NoveColors.secondaryText(context)),
                      ),
                      const SizedBox(height: 24),
                      if (_needsAccessibilityPermission)
                        ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            await AppLinkService.openAccessibilitySettings();
                          },
                          icon: const Icon(Icons.settings_accessibility, size: 18),
                          label: const Text('Grant Accessibility'),
=======
                      Icon(Icons.settings_accessibility,
                          size: 48, color: NoveColors.accent(context)),
                      const SizedBox(height: 16),
                      Text(
                        // FIX: Show clearer message for non-Android
                        Platform.isAndroid
                            ? 'Accessibility Required'
                            : 'Android Only',
                        style: GoogleFonts.lora(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Platform.isAndroid
                            ? 'NOVE needs Accessibility permissions to detect when you launch an app. We do not track or read your screen content.'
                            : 'App linking is only available on Android. It uses the Accessibility Service to detect when a linked app is opened.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            color: NoveColors.secondaryText(context)),
                      ),
                      const SizedBox(height: 24),
                      if (Platform.isAndroid)
                        ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            await AppLinkService.openAccessibilitySettings();
                            if (!context.mounted) return; // FIX: mounted guard
                            Navigator.pop(context);
                          },
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NoveColors.accent(context),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
<<<<<<< HEAD
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      if (_needsAccessibilityPermission && _needsOverlayPermission)
                        const SizedBox(height: 12),
                      if (_needsOverlayPermission)
                        ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            await FlutterOverlayWindow.requestPermission();
                          },
                          icon: const Icon(Icons.layers, size: 18),
                          label: const Text('Grant Display Over Apps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NoveColors.terracotta,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        )
=======
                          ),
                          child: const Text('Open Settings'),
                        )
                      else
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: TextStyle(color: NoveColors.accent(context)),
                          ),
                        ),
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                    ],
                  ),
                ),
              ),
            )
          ] else if (_isLoading) ...[
            Expanded(
              child: Center(
<<<<<<< HEAD
                child: CircularProgressIndicator(color: NoveColors.accent(context)),
=======
                child:
                    CircularProgressIndicator(color: NoveColors.accent(context)),
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
              ),
            )
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: NoveColors.cardBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _filteredApps = _apps
<<<<<<< HEAD
                        .where((a) => a.name.toLowerCase().contains(val.toLowerCase()))
=======
                        .where((a) =>
                            a.name.toLowerCase().contains(val.toLowerCase()))
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                        .toList();
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredApps.length,
                itemBuilder: (context, index) {
                  final app = _filteredApps[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
<<<<<<< HEAD
                        color: isDark ? NoveColors.cardDarkLight : NoveColors.warmGray100,
=======
                        color: isDark
                            ? NoveColors.cardDarkLight
                            : NoveColors.warmGray100,
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.apps),
                    ),
<<<<<<< HEAD
                    title: Text(
                      app.name, 
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: NoveColors.primaryText(context)
                      )
                    ),
                    subtitle: Text(
                      app.packageName,
                      style: GoogleFonts.dmSans(fontSize: 11, color: NoveColors.mutedText(context)),
=======
                    title: Text(app.name,
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            color: NoveColors.primaryText(context))),
                    subtitle: Text(
                      app.packageName,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: NoveColors.mutedText(context)),
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                    ),
                    onTap: () {
                      widget.onAppSelected(app);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            )
          ],
        ],
      ),
    );
  }
}