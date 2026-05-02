import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/security_service.dart';
import '../theme/tokens.dart';

class LockScreen extends StatefulWidget {
  final Widget child; 
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isLockEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkLockStatus() async {
    final enabled = await SecurityService.isLockEnabled();
    setState(() => _isLockEnabled = enabled);

    if (enabled && !_isAuthenticated) {
      _promptAuth();
    } else {
      setState(() => _isAuthenticated = true);
    }
  }

  Future<void> _promptAuth() async {
    final success = await SecurityService.authenticate();
    if (success && mounted) {
      setState(() => _isAuthenticated = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isLockEnabled) {
      // Re-lock the app the second it goes to the background
      setState(() => _isAuthenticated = false);
    } else if (state == AppLifecycleState.resumed && _isLockEnabled && !_isAuthenticated) {
      _promptAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLockEnabled || _isAuthenticated) {
      return widget.child;
    }

    // The beautiful lock overlay
    return Scaffold(
      backgroundColor: NoveColors.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: NoveColors.cardBg(context),
                shape: BoxShape.circle,
                boxShadow: NoveShadows.cardElevated(context),
              ),
              child: const Icon(Icons.fingerprint_rounded, size: 36, color: NoveColors.terracotta),
            ),
            const SizedBox(height: 24),
            Text(
              'NOVE is Locked',
              style: GoogleFonts.lora(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NoveColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verify your identity to access your workspace.',
              style: GoogleFonts.dmSans(color: NoveColors.secondaryText(context)),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _promptAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: NoveColors.accent(context),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: Text('Unlock', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}