import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sticky_note.dart';

// ─── State for one overlay sticky ────────────────────────────────────────────
class OverlayStickyEntry {
  final StickyNote note;
  final bool isMinimized; // true = small pill button, false = full sticky card
  final double posX;
  final double posY;

  const OverlayStickyEntry({
    required this.note,
    this.isMinimized = false, // starts as full sticky when popped out
    this.posX = 40,
    this.posY = 160,
  });

  OverlayStickyEntry copyWith({
    StickyNote? note,
    bool? isMinimized,
    double? posX,
    double? posY,
  }) {
    return OverlayStickyEntry(
      note: note ?? this.note,
      isMinimized: isMinimized ?? this.isMinimized,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class OverlayStickyNotifier extends StateNotifier<List<OverlayStickyEntry>> {
  OverlayStickyNotifier() : super([]);

  /// Pop a sticky note out — appears as full card overlay
  void popOut(StickyNote note) {
    // If already floating, don't add duplicate
    final exists = state.any((e) => e.note.id == note.id);
    if (exists) return;

    // Stagger position so multiple stickies don't stack perfectly
    final offset = state.length * 28.0;
    state = [
      ...state,
      OverlayStickyEntry(
        note: note,
        isMinimized: false,
        posX: 24 + offset,
        posY: 140 + offset,
      ),
    ];
  }

  /// Minimize to a small pill/button
  void minimize(String noteId) {
    state = state.map((e) {
      if (e.note.id == noteId) return e.copyWith(isMinimized: true);
      return e;
    }).toList();
  }

  /// Expand back to full sticky card (double-tap on minimized button)
  void expand(String noteId) {
    state = state.map((e) {
      if (e.note.id == noteId) return e.copyWith(isMinimized: false);
      return e;
    }).toList();
  }

  /// Remove from overlay entirely (goes back to board or is dismissed)
  void removeFromOverlay(String noteId) {
    state = state.where((e) => e.note.id != noteId).toList();
  }

  /// Update position after dragging
  void updatePosition(String noteId, double x, double y) {
    state = state.map((e) {
      if (e.note.id == noteId) return e.copyWith(posX: x, posY: y);
      return e;
    }).toList();
  }
}

final overlayStickyProvider =
    StateNotifierProvider<OverlayStickyNotifier, List<OverlayStickyEntry>>(
  (ref) => OverlayStickyNotifier(),
);