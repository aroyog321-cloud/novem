import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/tokens.dart';
import '../services/note_service.dart';

class FloatingCompanion extends StatefulWidget {
  const FloatingCompanion({super.key});

  @override
  State<FloatingCompanion> createState() => _FloatingCompanionState();
}

class _FloatingCompanionState extends State<FloatingCompanion>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _visible = true;
  Offset _position = const Offset(16, 100);
  final _controller = TextEditingController();
  late final AnimationController _bobController;
  late final Animation<double> _bobAnim;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
    _expandAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeOut),
    );
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('companion_enabled') ?? true;
    if (mounted) setState(() => _visible = enabled);
  }

  @override
  void dispose() {
    _bobController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
    if (_expanded) _bobController.stop();
    else _bobController.repeat(reverse: true);
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.mediumImpact();
      await NoteService.createNote(text);
      _controller.clear();
    }
    setState(() => _expanded = false);
    _bobController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // ── Expanded quick-capture card ───────────────────────────────
        if (_expanded)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: NoveAnimation.normal,
                decoration: BoxDecoration(
                  color: NoveColors.cardBg(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: NoveColors.cardBorder(context), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: NoveColors.warmGray300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 8, 0),
                      child: Row(
                        children: [
                          Text(
                            'Quick Note',
                            style: GoogleFonts.lora(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: NoveColors.primaryText(context),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _toggle,
                            icon: Icon(Icons.close_rounded,
                                size: 18,
                                color: NoveColors.secondaryText(context)),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Text input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        maxLines: 4,
                        style: GoogleFonts.caveat(
                          fontSize: 22,
                          color: NoveColors.primaryText(context),
                          height: 1.4,
                        ),
                        cursorColor: NoveColors.accent(context),
                        decoration: InputDecoration(
                          hintText:
                              'Capture the thought before it escapes...',
                          hintStyle: GoogleFonts.caveat(
                            fontSize: 20,
                            color: NoveColors.mutedText(context),
                          ),
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _save,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: NoveColors.accent(context),
                                borderRadius:
                                    BorderRadius.circular(NoveRadii.full),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.save_rounded,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Save note',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Draggable Bubble ──────────────────────────────────────────
        if (!_expanded)
          Positioned(
            top: _position.dy,
            left: _position.dx,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _position = Offset(
                    (_position.dx + details.delta.dx).clamp(
                        0,
                        MediaQuery.of(context).size.width - 60),
                    (_position.dy + details.delta.dy).clamp(
                        0,
                        MediaQuery.of(context).size.height - 160),
                  );
                });
              },
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _bobAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _bobAnim.value),
                  child: child,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: NoveColors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: NoveColors.amber.withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.edit_rounded,
                      size: 24,
                      color:
                          isDark ? NoveColors.warmGray900 : const Color(0xFF412402),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}