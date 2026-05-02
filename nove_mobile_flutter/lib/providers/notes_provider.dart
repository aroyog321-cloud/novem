import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/note_service.dart';
import '../models/note.dart';

class NotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? searchQuery;

  NotesState({this.notes = const [], this.isLoading = false, this.searchQuery});

  NotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? searchQuery,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  NotesNotifier() : super(NotesState(isLoading: true)) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    if (state.notes.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final notes = await NoteService.getAllNotes();
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, searchQuery: query);
    try {
      final notes = await NoteService.searchNotes(query);
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Note> createNote(
    String content, {
    String? title,
    String colorLabel = '#FFFFFF',
    String? category,
  }) async {
    final note = await NoteService.createNote(content, titleOverride: title, colorLabel: colorLabel, category: category);
    // Optimistic: prepend immediately, then sync from disk
    state = state.copyWith(notes: [note, ...state.notes]);
    await loadNotes();
    return note;
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
  }

  Future<void> deleteNote(String id) async {
    // Optimistic remove first so the card disappears instantly
    state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());
    await NoteService.deleteNote(id);
  }

  Future<void> togglePin(String id) async {
    await NoteService.togglePin(id);
    await loadNotes();
  }

  Future<void> toggleFavorite(String id) async {
    await NoteService.toggleFavorite(id);
    await loadNotes();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier();
});

final databaseInitProvider = FutureProvider<void>((ref) async {
  await NoteService.getAllNotes();
});