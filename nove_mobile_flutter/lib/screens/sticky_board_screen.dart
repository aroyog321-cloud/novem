import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import '../theme/tokens.dart';
import '../models/sticky_note.dart';
import '../providers/sticky_notes_provider.dart';
import '../widgets/app_link_picker.dart';
import '../widgets/overlay_sticky_provider.dart';

// ─── Custom Clippers & Painters ─────────────────────────────────────────────
class PeeledCornerClipper extends CustomClipper<Path> {
  final double foldSize;
  PeeledCornerClipper({this.foldSize = 20.0});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - foldSize)
      ..lineTo(size.width - foldSize, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class PeeledCornerPainter extends CustomPainter {
  final double foldSize;
  PeeledCornerPainter({this.foldSize = 20.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, size.height - foldSize)
      ..lineTo(size.width - foldSize, size.height - foldSize)
      ..lineTo(size.width - foldSize, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class StickyBoardScreen extends ConsumerStatefulWidget {
  const StickyBoardScreen({super.key});

  @override
  ConsumerState<StickyBoardScreen> createState() => _StickyBoardScreenState();
}

class _StickyBoardScreenState extends ConsumerState<StickyBoardScreen> {
  final _inputController = TextEditingController();
  StickyColor _selectedColor = StickyColor.yellow;
  final Map<String, Offset> _positions = {};
  Timer? _overlayCheckTimer;
  final double _gridSnapSize = 32.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stickyNotesProvider.notifier).loadNotes();
    });

    if (Platform.isAndroid) {
      _overlayCheckTimer =
          Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        final poppedNote = ref.read(poppedOutNoteProvider);
        if (poppedNote != null) {
          try {
            final isActive = await FlutterOverlayWindow.isActive();
            if (!isActive) {
              ref.read(poppedOutNoteProvider.notifier).state = null;
            }
          } catch (_) {}
        }
      });
    }
  }

  @override
  void dispose() {
    _overlayCheckTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _addNote() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      ref.read(stickyNotesProvider.notifier).createNote(text, _selectedColor);
      _inputController.clear();
      HapticFeedback.mediumImpact();
    }
  }

  void _deleteNote(String id) {
    ref.read(stickyNotesProvider.notifier).moveToTrash(id);
    _positions.remove(id);
  }

  void _updateNoteContent(String id, String content) {
    ref.read(stickyNotesProvider.notifier).updateNoteContent(id, content);
  }

  void _togglePin(String id) {
    HapticFeedback.lightImpact();
    ref.read(stickyNotesProvider.notifier).togglePin(id);
  }

  Color _getNoteColor(StickyColor color) {
    switch (color) {
      case StickyColor.yellow: return const Color(0xFFF5C842);
      case StickyColor.pink:   return const Color(0xFFF2C2D8);
      case StickyColor.green:  return const Color(0xFFC5EDBE);
      case StickyColor.blue:   return const Color(0xFFB3E5FC);
    }
  }

  void _minimizeNote(StickyNote note) async {
    if (!Platform.isAndroid) {
      ref.read(overlayStickyProvider.notifier).popOut(note);
      return;
    }

    final poppedNote = ref.read(poppedOutNoteProvider);
    if (poppedNote != null && poppedNote.id != note.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Only 1 floating note at a time. Restore your active note first.'),
        ));
      }
      return;
    }

    ref.read(poppedOutNoteProvider.notifier).state = note;

    try {
      bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        final requested = await FlutterOverlayWindow.requestPermission();
        if (requested != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Overlay permission is required to float notes.'),
            ));
          }
          return;
        }
      }

      final data = jsonEncode({
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'color': _getNoteColor(note.color).value,
        'isBubble': true,
      });

      bool isActive = false;
      try { isActive = await FlutterOverlayWindow.isActive(); } catch (_) {}

      if (isActive) {
        await FlutterOverlayWindow.resizeOverlay(100, 100, true);
        await FlutterOverlayWindow.shareData("note:$data");
      } else {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          height: 100,
          width: 100,
          alignment: OverlayAlignment.centerRight,
        );
        await Future.delayed(const Duration(milliseconds: 400));
        await FlutterOverlayWindow.shareData("note:$data");
      }
    } catch (e) {
      debugPrint('Overlay blocked or crashed: $e');
    }
  }

  void _showAppPicker(BuildContext context, StickyNote note) {
    showAppLinkPicker(
      context: context,
      onAppSelected: (app) {
        ref.read(stickyNotesProvider.notifier).linkApp(note.id, app.packageName, app.name);
      },
    );
  }

  Offset _snapToGrid(Offset position) {
    return Offset(
      math.max(0, (position.dx / _gridSnapSize).round() * _gridSnapSize),
      math.max(0, (position.dy / _gridSnapSize).round() * _gridSnapSize),
    );
  }

  Offset _getGridPosition(int index, double screenWidth) {
    const double cardWidth  = 160.0;
    const double cardHeight = 200.0;
    const double padding    = 24.0;
    const double spacing    = 16.0;

    final double availableWidth = screenWidth - (padding * 2);
    int columns = (availableWidth + spacing) ~/ (cardWidth + spacing);
    if (columns < 1) columns = 1;

    final double colSpacing = columns > 1
        ? (availableWidth - (columns * cardWidth)) / (columns - 1)
        : 0;

    final int col = index % columns;
    final int row = index ~/ columns;

    return _snapToGrid(Offset(
      padding + col * (cardWidth + colSpacing),
      padding + row * (cardHeight + spacing),
    ));
  }

  void _arrangeNotes(List<StickyNote> visibleNotes, double screenWidth) {
    HapticFeedback.mediumImpact();
    setState(() {
      for (int i = 0; i < visibleNotes.length; i++) {
        _positions[visibleNotes[i].id] = _getGridPosition(i, screenWidth);
      }
    });
  }

  Offset _getUnoccupiedGridPosition(double screenWidth) {
    for (int i = 0; i < 1000; i++) {
      final pos = _getGridPosition(i, screenWidth);
      final occupied = _positions.values.any(
        (e) => (e.dx - pos.dx).abs() < 20 && (e.dy - pos.dy).abs() < 20,
      );
      if (!occupied) return pos;
    }
    return _getGridPosition(0, screenWidth);
  }

  @override
  Widget build(BuildContext context) {
    final allNotes   = ref.watch(stickyNotesProvider);
    final poppedNote = ref.watch(poppedOutNoteProvider);
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    // FIX: ref.watch so isPinned changes trigger rebuild
    final notifier   = ref.watch(stickyNotesProvider.notifier);

    final visibleNotes = allNotes.where((n) => n.id != poppedNote?.id).toList();
    visibleNotes.sort((a, b) {
      final aPinned = notifier.isPinned(a.id);
      final bPinned = notifier.isPinned(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: NoveColors.bg(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(isDark: isDark, spacing: _gridSnapSize),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sticky Board',
                            style: NoveTypography.lora(
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: NoveColors.terracotta,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'VISUAL BRAINSTORMING ARENA',
                            style: NoveTypography.dmsans(
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: NoveColors.mutedText(context),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (Platform.isAndroid)
                            IconButton(
                              onPressed: () async {
                                try { await FlutterOverlayWindow.closeOverlay(); } catch (_) {}
                                ref.read(poppedOutNoteProvider.notifier).state = null;
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Floating note restored.')),
                                );
                              },
                              icon: const Icon(Icons.settings_backup_restore, color: NoveColors.terracotta),
                              tooltip: 'Restore Floating Note',
                              style: IconButton.styleFrom(backgroundColor: NoveColors.cardBg(context)),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _arrangeNotes(visibleNotes, MediaQuery.of(context).size.width),
                            icon: const Icon(Icons.grid_view, color: NoveColors.terracotta),
                            tooltip: 'Arrange Board',
                            style: IconButton.styleFrom(backgroundColor: NoveColors.cardBg(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visibleNotes.isEmpty
                      ? Center(
                          child: Text(
                            'No sticky notes yet.\nAdd one below!',
                            textAlign: TextAlign.center,
                            style: NoveTypography.dmsans(
                              style: TextStyle(
                                fontSize: 16,
                                color: NoveColors.mutedText(context),
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 120),
                          child: SizedBox(
                            height: math.max(
                              1000,
                              (visibleNotes.length / 2).ceil() * 220.0 + 100,
                            ),
                            width: double.infinity,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: visibleNotes.asMap().entries.map((entry) {
                                final note     = entry.value;
                                final isPinned = notifier.isPinned(note.id);
                                final screenWidth = MediaQuery.of(context).size.width;

                                _positions.putIfAbsent(
                                  note.id,
                                  () => _getUnoccupiedGridPosition(screenWidth),
                                );
                                final pos = _positions[note.id]!;

                                return AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutBack,
                                  key: ValueKey(note.id),
                                  left: pos.dx,
                                  top: pos.dy,
                                  child: SizedBox(
                                    width: 160,
                                    height: 200,
                                    child: _StickyCard(
                                      note: note,
                                      isPinned: isPinned,
                                      onDelete: () => _deleteNote(note.id),
                                      onMinimize: () => _minimizeNote(note),
                                      onTogglePin: () => _togglePin(note.id),
                                      onLinkApp: () => _showAppPicker(context, note),
                                      onContentChanged: (t) => _updateNoteContent(note.id, t),
                                      onDragUpdate: (details) {
                                        setState(() {
                                          _positions[note.id] = Offset(
                                            math.max(0, pos.dx + details.delta.dx),
                                            math.max(0, pos.dy + details.delta.dy),
                                          );
                                        });
                                      },
                                      onDragEnd: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _positions[note.id] = _snapToGrid(_positions[note.id]!);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _InputBar(
        controller: _inputController,
        selectedColor: _selectedColor,
        isDark: isDark,
        onColorChanged: (c) {
          HapticFeedback.selectionClick();
          setState(() => _selectedColor = c);
        },
        onAdd: _addNote,
      ),
    );
  }
}

// ─── Dot-grid background painter ─────────────────────────────────────────────
class DotGridPainter extends CustomPainter {
  final bool isDark;
  final double spacing;
  DotGridPainter({required this.isDark, this.spacing = 32.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? NoveColors.warmGray800.withValues(alpha: 0.5)
          : NoveColors.warmGray300.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter old) => old.isDark != isDark;
}

// ─── Sticky card ──────────────────────────────────────────────────────────────
class _StickyCard extends StatefulWidget {
  final StickyNote note;
  final bool isPinned;
  final VoidCallback onDelete;
  final VoidCallback onMinimize;
  final VoidCallback onTogglePin;
  final VoidCallback onLinkApp;
  final ValueChanged<String> onContentChanged;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;

  const _StickyCard({
    required this.note,
    required this.isPinned,
    required this.onDelete,
    required this.onMinimize,
    required this.onTogglePin,
    required this.onLinkApp,
    required this.onContentChanged,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_StickyCard> createState() => _StickyCardState();
}

class _StickyCardState extends State<_StickyCard> {
  late TextEditingController _textController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.note.content);
  }

  @override
  void didUpdateWidget(_StickyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.content != widget.note.content) {
      _textController.text = widget.note.content;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.note.color) {
      case StickyColor.yellow: return const Color(0xFFF5C842);
      case StickyColor.pink:   return const Color(0xFFF2C2D8);
      case StickyColor.green:  return const Color(0xFFC5EDBE);
      case StickyColor.blue:   return const Color(0xFFB3E5FC);
    }
  }

  void _confirmDelete() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NoveColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Move to Trash',
          style: TextStyle(
            color: NoveColors.primaryText(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Move this sticky note to the trash bin?',
          style: TextStyle(color: NoveColors.secondaryText(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel',
                style: TextStyle(color: NoveColors.primaryText(context))),
          ),
          TextButton(
            onPressed: () {
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              widget.onDelete();
            },
            child: const Text('Trash',
                style: TextStyle(
                    color: NoveColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ROOT FIX EXPLAINED:
    // Old layout crammed 4 icons (18px each + 2px padding = ~22px each = 88px)
    // + drag icon into a single Row inside a card with only 128px of usable
    // width (160 - 16 padding each side). Result: overflow + ClipPath cutting
    // off the rightmost buttons (especially delete).
    //
    // New layout divides the card into 3 vertical zones:
    //   Zone 1 (top,    28px): Full-width drag handle bar — easy to grab
    //   Zone 2 (middle, flex): Note title + editable text content
    //   Zone 3 (bottom, 32px): Button toolbar — 4 buttons × 36px = 144px,
    //                          spaced evenly in 160px width with spaceEvenly.
    //                          All buttons are inside the card, none overflow.

    const double foldSize = 20.0;

    return AnimatedScale(
      scale: _isDragging ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedRotation(
        turns: _isDragging ? 0.02 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF31312D)
                    .withValues(alpha: _isDragging ? 0.3 : 0.15),
                blurRadius: _isDragging ? 24 : 16,
                offset: Offset(0, _isDragging ? 12 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipPath(
                clipper: PeeledCornerClipper(foldSize: foldSize),
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Zone 1: Drag handle (full-width bar, easy grab area) ──
                      GestureDetector(
                        onPanStart: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _isDragging = true);
                        },
                        onPanEnd: (_) {
                          setState(() => _isDragging = false);
                          widget.onDragEnd();
                        },
                        onPanCancel: () {
                          setState(() => _isDragging = false);
                          widget.onDragEnd();
                        },
                        onPanUpdate: widget.onDragUpdate,
                        child: Container(
                          width: double.infinity,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.drag_handle_rounded,
                              size: 18,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ),

                      // ── Zone 2: Content ───────────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.note.title.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    widget.note.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: NoveTypography.dmsans(
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1C1C18),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: TextFormField(
                                  controller: _textController,
                                  onChanged: widget.onContentChanged,
                                  maxLines: null,
                                  expands: true,
                                  style: NoveTypography.caveat(
                                    style: const TextStyle(
                                      fontSize: 20,
                                      height: 1.2,
                                      color: Color(0xCC1C1C18),
                                    ),
                                  ),
                                  decoration: const InputDecoration(
                                    filled: false,
                                    border: InputBorder.none,
                                    hintText: 'Write here...',
                                    hintStyle: TextStyle(color: Colors.black26),
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Zone 3: Button toolbar (bottom, inside card) ──────────
                      // 4 buttons × 36px touch target = 144px, fits in 160px card.
                      // mainAxisAlignment.spaceEvenly distributes them cleanly.
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.07),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CardBtn(
                              icon: widget.note.linkedApp != null
                                  ? Icons.link_rounded
                                  : Icons.link_off_rounded,
                              color: widget.note.linkedApp != null
                                  ? Colors.blue.shade700
                                  : Colors.black45,
                              onTap: widget.onLinkApp,
                              tooltip: 'Link App',
                            ),
                            _CardBtn(
                              icon: Icons.open_in_new_rounded,
                              color: Colors.black45,
                              onTap: widget.onMinimize,
                              tooltip: 'Float note',
                            ),
                            _CardBtn(
                              icon: widget.isPinned
                                  ? Icons.push_pin_rounded
                                  : Icons.push_pin_outlined,
                              color: widget.isPinned
                                  ? NoveColors.terracotta
                                  : Colors.black45,
                              onTap: widget.onTogglePin,
                              tooltip: widget.isPinned ? 'Unpin' : 'Pin',
                            ),
                            _CardBtn(
                              icon: Icons.delete_outline_rounded,
                              color: Colors.red.shade400,
                              onTap: _confirmDelete,
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              // Peeled corner shadow
              Positioned.fill(
                child: CustomPaint(
                  painter: PeeledCornerPainter(foldSize: foldSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compact card button ──────────────────────────────────────────────────────
class _CardBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _CardBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 32,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final StickyColor selectedColor;
  final ValueChanged<StickyColor> onColorChanged;
  final VoidCallback onAdd;
  final bool isDark;

  const _InputBar({
    required this.controller,
    required this.selectedColor,
    required this.onColorChanged,
    required this.onAdd,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = {
      StickyColor.yellow: const Color(0xFFF5C842),
      StickyColor.pink:   const Color(0xFFF2C2D8),
      StickyColor.green:  const Color(0xFFC5EDBE),
      StickyColor.blue:   const Color(0xFFB3E5FC),
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 90),
      decoration: BoxDecoration(
        color: NoveColors.cardBg(context).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? Border(
                top: BorderSide(color: NoveColors.cardBorder(context), width: 1))
            : null,
      ),
      child: Row(
        children: [
          Row(
            children: colors.entries.map((e) {
              return GestureDetector(
                onTap: () => onColorChanged(e.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: e.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedColor == e.key
                          ? NoveColors.terracotta
                          : (isDark ? Colors.transparent : Colors.white),
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  color: NoveColors.primaryText(context)),
              decoration: InputDecoration(
                hintText: 'Title (optional)...',
                hintStyle: TextStyle(color: NoveColors.mutedText(context)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Add',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: NoveColors.terracotta,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}