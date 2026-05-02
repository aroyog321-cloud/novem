import { executeQuery, executeUpdate } from '../database';
import { Note } from '../types';

interface NoteRow {
  id: string;
  title: string;
  content: string;
  category: string | null;
  color_label: string;
  is_pinned: number;
  is_favorite: number;
  created_at: number;
  updated_at: number;
  word_count: number;
  char_count: number;
  read_time_minutes: number;
}

const mapRowToNote = (row: NoteRow): Note => ({
  id: row.id,
  title: row.title,
  content: row.content,
  category: row.category,
  colorLabel: row.color_label,
  isPinned: row.is_pinned === 1,
  isFavorite: row.is_favorite === 1,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  wordCount: row.word_count,
  charCount: row.char_count,
  readTimeMinutes: row.read_time_minutes,
});

const calculateReadTime = (content: string): number => {
  const wordCount = content.trim().split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.ceil(wordCount / 200));
};

const calculateWordCount = (content: string): number => {
  return content.trim().split(/\s+/).filter(Boolean).length;
};

const extractTitle = (content: string): string => {
  const firstLine = content.split('\n')[0]?.trim() || 'Untitled';
  return firstLine.length > 100 ? firstLine.substring(0, 97) + '...' : firstLine;
};

export class NoteService {
  static getAllNotes(): Note[] {
    const rows = executeQuery<NoteRow>(
      'SELECT * FROM notes ORDER BY is_pinned DESC, updated_at DESC'
    );
    return rows.map(mapRowToNote);
  }

  static getNotesByCategory(category: string): Note[] {
    const rows = executeQuery<NoteRow>(
      'SELECT * FROM notes WHERE category = ? ORDER BY is_pinned DESC, updated_at DESC',
      [category]
    );
    return rows.map(mapRowToNote);
  }

  static getNoteById(id: string): Note | null {
    const rows = executeQuery<NoteRow>(
      'SELECT * FROM notes WHERE id = ?',
      [id]
    );
    return rows.length > 0 ? mapRowToNote(rows[0]) : null;
  }

  static getPinnedNotes(): Note[] {
    const rows = executeQuery<NoteRow>(
      'SELECT * FROM notes WHERE is_pinned = 1 ORDER BY updated_at DESC'
    );
    return rows.map(mapRowToNote);
  }

  static getFavoriteNotes(): Note[] {
    const rows = executeQuery<NoteRow>(
      'SELECT * FROM notes WHERE is_favorite = 1 ORDER BY updated_at DESC'
    );
    return rows.map(mapRowToNote);
  }

  static searchNotes(query: string): Note[] {
    const searchTerm = `%${query}%`;
    const rows = executeQuery<NoteRow>(
      'SELECT * FROM notes WHERE title LIKE ? OR content LIKE ? ORDER BY updated_at DESC',
      [searchTerm, searchTerm]
    );
    return rows.map(mapRowToNote);
  }

  static createNote(content: string, category: string | null = null, colorLabel: string = '#FFFFFF'): Note {
    const now = Date.now();
    const id = `note_${now}_${Math.random().toString(36).substr(2, 9)}`;
    const title = extractTitle(content);
    const wordCount = calculateWordCount(content);
    const charCount = content.length;
    const readTimeMinutes = calculateReadTime(content);

    executeUpdate(
      `INSERT INTO notes (id, title, content, category, color_label, is_pinned, is_favorite, created_at, updated_at, word_count, char_count, read_time_minutes)
       VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?, ?)`,
      [id, title, content, category, colorLabel, now, now, wordCount, charCount, readTimeMinutes]
    );

    return {
      id,
      title,
      content,
      category,
      colorLabel,
      isPinned: false,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
      wordCount,
      charCount,
      readTimeMinutes,
    };
  }

  static updateNote(
    id: string,
    updates: Partial<Pick<Note, 'content' | 'category' | 'colorLabel' | 'isPinned' | 'isFavorite'>>
  ): Note | null {
    const existing = this.getNoteById(id);
    if (!existing) return null;

    const now = Date.now();
    const content = updates.content ?? existing.content;
    const title = extractTitle(content);
    const wordCount = calculateWordCount(content);
    const charCount = content.length;
    const readTimeMinutes = calculateReadTime(content);

    const category = updates.category !== undefined ? updates.category : existing.category;
    const colorLabel = updates.colorLabel ?? existing.colorLabel;
    const isPinned = updates.isPinned ?? existing.isPinned;
    const isFavorite = updates.isFavorite ?? existing.isFavorite;

    executeUpdate(
      `UPDATE notes SET title = ?, content = ?, category = ?, color_label = ?, is_pinned = ?, is_favorite = ?, updated_at = ?, word_count = ?, char_count = ?, read_time_minutes = ?
       WHERE id = ?`,
      [title, content, category, colorLabel, isPinned ? 1 : 0, isFavorite ? 1 : 0, now, wordCount, charCount, readTimeMinutes, id]
    );

    return this.getNoteById(id);
  }

  static deleteNote(id: string): boolean {
    const affected = executeUpdate('DELETE FROM notes WHERE id = ?', [id]);
    return affected > 0;
  }

  static togglePin(id: string): Note | null {
    const note = this.getNoteById(id);
    if (!note) return null;
    return this.updateNote(id, { isPinned: !note.isPinned });
  }

  static toggleFavorite(id: string): Note | null {
    const note = this.getNoteById(id);
    if (!note) return null;
    return this.updateNote(id, { isFavorite: !note.isFavorite });
  }

  static getNotesCount(): number {
    const result = executeQuery<{ count: number }>('SELECT COUNT(*) as count FROM notes');
    return result[0]?.count ?? 0;
  }
}
