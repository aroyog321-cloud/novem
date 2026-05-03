import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/note_service.dart';
import '../models/note.dart';

class NotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? searchQuery;
<<<<<<< HEAD
  final String? error;

  NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.searchQuery,
    this.error,
  });
=======

  NotesState({this.notes = const [], this.isLoading = false, this.searchQuery});
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f

  NotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? searchQuery,
<<<<<<< HEAD
    String? error,
=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
<<<<<<< HEAD
      error: error ?? this.error,
=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  NotesNotifier() : super(NotesState(isLoading: true)) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    if (state.notes.isEmpty) {
<<<<<<< HEAD
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final notes = await NoteService.getAllNotes();
      state = state.copyWith(notes: notes, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
=======
      state = state.copyWith(isLoading: true);
    }
    try {
      final notes = await NoteService.getAllNotes();
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    }
  }

  Future<void> search(String query) async {
<<<<<<< HEAD
    state = state.copyWith(isLoading: true, searchQuery: query, error: null);
=======
    state = state.copyWith(isLoading: true, searchQuery: query);
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    try {
      final notes = await NoteService.searchNotes(query);
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
<<<<<<< HEAD
      state = state.copyWith(isLoading: false, error: e.toString());
=======
      state = state.copyWith(isLoading: false);
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    }
  }

  Future<Note> createNote(
    String content, {
    String? title,
    String colorLabel = '#FFFFFF',
    String? category,
<<<<<<< HEAD
    bool isPinned = false,
    bool isFavorite = false,
  }) async {
    try {
      final note = await NoteService.createNote(
        content,
        titleOverride: title,
        colorLabel: colorLabel,
        category: category,
        isPinned: isPinned,
        isFavorite: isFavorite,
      );
      // Optimistic: prepend immediately
      state = state.copyWith(notes: [note, ...state.notes]);
      return note;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
=======
  }) async {
    final note = await NoteService.createNote(content, titleOverride: title, colorLabel: colorLabel, category: category);
    // Optimistic: prepend immediately, then sync from disk
    state = state.copyWith(notes: [note, ...state.notes]);
    await loadNotes();
    return note;
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  }

  Future<void> updateNote(
    String id, {
    String? title,
    String? content,
    bool? isPinned,
    bool? isFavorite,
    String? colorLabel,
    String? category,
  }) async {
<<<<<<< HEAD
    try {
      await NoteService.updateNote(
        id,
        title: title,
        content: content,
        isPinned: isPinned,
        isFavorite: isFavorite,
        colorLabel: colorLabel,
        category: category,
      );
      // Optimistic local update — no DB round-trip
      final updatedNotes = state.notes.map((n) {
        if (n.id != id) return n;
        return n.copyWith(
          title: title ?? n.title,
          content: content ?? n.content,
          isPinned: isPinned ?? n.isPinned,
          isFavorite: isFavorite ?? n.isFavorite,
          colorLabel: colorLabel ?? n.colorLabel,
          category: category ?? n.category,
        );
      }).toList();
      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await loadNotes(); // Re-sync on error
    }
=======
    await NoteService.updateNote(
      id,
      title: title,
      content: content,
      isPinned: isPinned,
      isFavorite: isFavorite,
      colorLabel: colorLabel,
      category: category,
    );
    // Optimistic local update, then sync
    final updatedNotes = state.notes.map((n) {
      if (n.id != id) return n;
      return n.copyWith(
        content: content ?? n.content,
        isPinned: isPinned ?? n.isPinned,
        isFavorite: isFavorite ?? n.isFavorite,
        colorLabel: colorLabel ?? n.colorLabel,
        category: category ?? n.category,
      );
    }).toList();
    state = state.copyWith(notes: updatedNotes);
    await loadNotes();
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  }

  Future<void> deleteNote(String id) async {
    // Optimistic remove first so the card disappears instantly
    state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());
<<<<<<< HEAD
    try {
      await NoteService.deleteNote(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await loadNotes(); // Re-sync on error
    }
  }

  /// Optimistic pin toggle — no DB round-trip on success
  Future<void> togglePin(String id) async {
    final current = state.notes.firstWhere((n) => n.id == id, orElse: () => throw StateError('Note not found'));
    final newPinned = !current.isPinned;
    state = state.copyWith(
      notes: state.notes.map((n) => n.id == id ? n.copyWith(isPinned: newPinned) : n).toList(),
    );
    try {
      await NoteService.togglePin(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await loadNotes(); // Re-sync on error
    }
  }

  /// Optimistic favorite toggle — no DB round-trip on success
  Future<void> toggleFavorite(String id) async {
    final current = state.notes.firstWhere((n) => n.id == id, orElse: () => throw StateError('Note not found'));
    final newFav = !current.isFavorite;
    state = state.copyWith(
      notes: state.notes.map((n) => n.id == id ? n.copyWith(isFavorite: newFav) : n).toList(),
    );
    try {
      await NoteService.toggleFavorite(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await loadNotes(); // Re-sync on error
    }
=======
    await NoteService.deleteNote(id);
  }

  Future<void> togglePin(String id) async {
    await NoteService.togglePin(id);
    await loadNotes();
  }

  Future<void> toggleFavorite(String id) async {
    await NoteService.toggleFavorite(id);
    await loadNotes();
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier();
});

final databaseInitProvider = FutureProvider<void>((ref) async {
  await NoteService.getAllNotes();
});