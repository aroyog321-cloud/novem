import { ipcMain } from 'electron';
import { executeQuery, executeInsert, executeUpdate } from './database';

interface Note {
  id: string;
  title: string;
  content: string;
  category: string | null;
  colorLabel: string;
  isPinned: boolean;
  isFavorite: boolean;
  createdAt: number;
  updatedAt: number;
  wordCount: number;
  charCount: number;
  readTimeMinutes: number;
}

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

interface StickyNote {
  id: string;
  title: string;
  content: string;
  color: string;
  positionX: number;
  positionY: number;
  createdAt: number;
  updatedAt: number;
}

interface StickyNoteRow {
  id: string;
  title: string;
  content: string;
  color: string;
  position_x: number;
  position_y: number;
  created_at: number;
  updated_at: number;
}

interface Category {
  id: string;
  name: string;
  color: string;
  order: number;
}

interface CategoryRow {
  id: string;
  name: string;
  color: string;
  sort_order: number;
}

interface FloatingCompanionState {
  isExpanded: boolean;
  isMinimized: boolean;
  lastActiveNoteId: string | null;
  positionX: number;
  positionY: number;
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

const mapRowToStickyNote = (row: StickyNoteRow): StickyNote => ({
  id: row.id,
  title: row.title,
  content: row.content,
  color: row.color,
  positionX: row.position_x,
  positionY: row.position_y,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

const mapRowToCategory = (row: CategoryRow): Category => ({
  id: row.id,
  name: row.name,
  color: row.color,
  order: row.sort_order,
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

const generateId = (): string => `note_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
const generateStickyId = (): string => `sticky_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
const generateCatId = (): string => `cat_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

export const setupIpcHandlers = (): void => {
  ipcMain.handle('notes:getAll', () => {
    const rows = executeQuery<NoteRow>('SELECT * FROM notes ORDER BY is_pinned DESC, updated_at DESC');
    return rows.map(mapRowToNote);
  });

  ipcMain.handle('notes:getById', (_, id: string) => {
    const rows = executeQuery<NoteRow>('SELECT * FROM notes WHERE id = ?', [id]);
    return rows.length > 0 ? mapRowToNote(rows[0]) : null;
  });

  ipcMain.handle('notes:getByCategory', (_, category: string) => {
    const rows = executeQuery<NoteRow>(
      'SELECT * FROM notes WHERE category = ? ORDER BY is_pinned DESC, updated_at DESC',
      [category]
    );
    return rows.map(mapRowToNote);
  });

  ipcMain.handle('notes:getPinned', () => {
    const rows = executeQuery<NoteRow>('SELECT * FROM notes WHERE is_pinned = 1 ORDER BY updated_at DESC');
    return rows.map(mapRowToNote);
  });

  ipcMain.handle('notes:getFavorites', () => {
    const rows = executeQuery<NoteRow>('SELECT * FROM notes WHERE is_favorite = 1 ORDER BY updated_at DESC');
    return rows.map(mapRowToNote);
  });

  ipcMain.handle('notes:search', (_, query: string) => {
    const searchTerm = `%${query}%`;
    const rows = executeQuery<NoteRow>(
      'SELECT * FROM notes WHERE title LIKE ? OR content LIKE ? ORDER BY updated_at DESC',
      [searchTerm, searchTerm]
    );
    return rows.map(mapRowToNote);
  });

  ipcMain.handle('notes:create', (_, content: string, category: string | null, colorLabel: string) => {
    const now = Date.now();
    const id = generateId();
    const title = extractTitle(content);
    const wordCount = calculateWordCount(content);
    const charCount = content.length;
    const readTimeMinutes = calculateReadTime(content);

    executeInsert(
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
  });

  ipcMain.handle('notes:update', (_, id: string, updates: Partial<Note>) => {
    const rows = executeQuery<NoteRow>('SELECT * FROM notes WHERE id = ?', [id]);
    if (rows.length === 0) return null;

    const existing = mapRowToNote(rows[0]);
    const now = Date.now();
    const content = updates.content ?? existing.content;
    const title = extractTitle(content);
    const wordCount = calculateWordCount(content);
    const charCount = content.length;
    const readTimeMinutes = calculateReadTime(content);

    executeUpdate(
      `UPDATE notes SET title = ?, content = ?, category = ?, color_label = ?, is_pinned = ?, is_favorite = ?, updated_at = ?, word_count = ?, char_count = ?, read_time_minutes = ?
       WHERE id = ?`,
      [
        title,
        content,
        updates.category !== undefined ? updates.category : existing.category,
        updates.colorLabel ?? existing.colorLabel,
        updates.isPinned ?? existing.isPinned ? 1 : 0,
        updates.isFavorite ?? existing.isFavorite ? 1 : 0,
        now,
        wordCount,
        charCount,
        readTimeMinutes,
        id,
      ]
    );

    return mapRowToNote(executeQuery<NoteRow>('SELECT * FROM notes WHERE id = ?', [id])[0]);
  });

  ipcMain.handle('notes:delete', (_, id: string) => {
    return executeUpdate('DELETE FROM notes WHERE id = ?', [id]) > 0;
  });

  ipcMain.handle('notes:togglePin', (_, id: string) => {
    const rows = executeQuery<NoteRow>('SELECT * FROM notes WHERE id = ?', [id]);
    if (rows.length === 0) return null;
    const note = mapRowToNote(rows[0]);
    executeUpdate('UPDATE notes SET is_pinned = ? WHERE id = ?', [note.isPinned ? 0 : 1, id]);
    return mapRowToNote(executeQuery<NoteRow>('SELECT * FROM notes WHERE id = ?', [id])[0]);
  });

  ipcMain.handle('notes:toggleFavorite', (_, id: string) => {
    const rows = executeQuery<NoteRow>('SELECT * FROM notes WHERE id = ?', [id]);
    if (rows.length === 0) return null;
    const note = mapRowToNote(rows[0]);
    executeUpdate('UPDATE notes SET is_favorite = ? WHERE id = ?', [note.isFavorite ? 0 : 1, id]);
    return mapRowToNote(executeQuery<NoteRow>('SELECT * FROM notes WHERE id = ?', [id])[0]);
  });

  ipcMain.handle('notes:getCount', () => {
    const result = executeQuery<{ count: number }>('SELECT COUNT(*) as count FROM notes');
    return result[0]?.count ?? 0;
  });

  ipcMain.handle('stickyNotes:getAll', () => {
    const rows = executeQuery<StickyNoteRow>('SELECT * FROM sticky_notes ORDER BY created_at DESC');
    return rows.map(mapRowToStickyNote);
  });

  ipcMain.handle('stickyNotes:getById', (_, id: string) => {
    const rows = executeQuery<StickyNoteRow>('SELECT * FROM sticky_notes WHERE id = ?', [id]);
    return rows.length > 0 ? mapRowToStickyNote(rows[0]) : null;
  });

  ipcMain.handle('stickyNotes:getByColor', (_, color: string) => {
    const rows = executeQuery<StickyNoteRow>(
      'SELECT * FROM sticky_notes WHERE color = ? ORDER BY created_at DESC',
      [color]
    );
    return rows.map(mapRowToStickyNote);
  });

  ipcMain.handle('stickyNotes:create', (_, title: string, content: string, color: string, positionX: number, positionY: number) => {
    const now = Date.now();
    const id = generateStickyId();

    executeInsert(
      `INSERT INTO sticky_notes (id, title, content, color, position_x, position_y, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, title, content, color, positionX, positionY, now, now]
    );

    return {
      id,
      title,
      content,
      color,
      positionX,
      positionY,
      createdAt: now,
      updatedAt: now,
    };
  });

  ipcMain.handle('stickyNotes:update', (_, id: string, updates: Partial<StickyNote>) => {
    const rows = executeQuery<StickyNoteRow>('SELECT * FROM sticky_notes WHERE id = ?', [id]);
    if (rows.length === 0) return null;

    const existing = mapRowToStickyNote(rows[0]);
    const now = Date.now();

    executeUpdate(
      `UPDATE sticky_notes SET title = ?, content = ?, color = ?, position_x = ?, position_y = ?, updated_at = ?
       WHERE id = ?`,
      [
        updates.title ?? existing.title,
        updates.content ?? existing.content,
        updates.color ?? existing.color,
        updates.positionX ?? existing.positionX,
        updates.positionY ?? existing.positionY,
        now,
        id,
      ]
    );

    return mapRowToStickyNote(executeQuery<StickyNoteRow>('SELECT * FROM sticky_notes WHERE id = ?', [id])[0]);
  });

  ipcMain.handle('stickyNotes:updatePosition', (_, id: string, positionX: number, positionY: number) => {
    executeUpdate('UPDATE sticky_notes SET position_x = ?, position_y = ?, updated_at = ? WHERE id = ?',
      [positionX, positionY, Date.now(), id]);
    return mapRowToStickyNote(executeQuery<StickyNoteRow>('SELECT * FROM sticky_notes WHERE id = ?', [id])[0]);
  });

  ipcMain.handle('stickyNotes:delete', (_, id: string) => {
    return executeUpdate('DELETE FROM sticky_notes WHERE id = ?', [id]) > 0;
  });

  ipcMain.handle('stickyNotes:getCount', () => {
    const result = executeQuery<{ count: number }>('SELECT COUNT(*) as count FROM sticky_notes');
    return result[0]?.count ?? 0;
  });

  ipcMain.handle('stickyNotes:clearAll', () => {
    return executeUpdate('DELETE FROM sticky_notes');
  });

  ipcMain.handle('categories:getAll', () => {
    const rows = executeQuery<CategoryRow>('SELECT * FROM categories ORDER BY sort_order ASC');
    return rows.map(mapRowToCategory);
  });

  ipcMain.handle('categories:getById', (_, id: string) => {
    const rows = executeQuery<CategoryRow>('SELECT * FROM categories WHERE id = ?', [id]);
    return rows.length > 0 ? mapRowToCategory(rows[0]) : null;
  });

  ipcMain.handle('categories:create', (_, name: string, color: string) => {
    const id = generateCatId();
    const maxOrder = executeQuery<{ max_order: number }>('SELECT MAX(sort_order) as max_order FROM categories');
    const order = (maxOrder[0]?.max_order ?? -1) + 1;

    executeInsert('INSERT INTO categories (id, name, color, sort_order) VALUES (?, ?, ?, ?)',
      [id, name, color, order]);

    return { id, name, color, order };
  });

  ipcMain.handle('categories:update', (_, id: string, updates: Partial<Category>) => {
    const rows = executeQuery<CategoryRow>('SELECT * FROM categories WHERE id = ?', [id]);
    if (rows.length === 0) return null;

    const existing = mapRowToCategory(rows[0]);
    executeUpdate('UPDATE categories SET name = ?, color = ?, sort_order = ? WHERE id = ?',
      [
        updates.name ?? existing.name,
        updates.color ?? existing.color,
        updates.order ?? existing.order,
        id,
      ]);
    return mapRowToCategory(executeQuery<CategoryRow>('SELECT * FROM categories WHERE id = ?', [id])[0]);
  });

  ipcMain.handle('categories:delete', (_, id: string) => {
    return executeUpdate('DELETE FROM categories WHERE id = ?', [id]) > 0;
  });

  ipcMain.handle('categories:reorder', (_, categoryIds: string[]) => {
    categoryIds.forEach((catId, index) => {
      executeUpdate('UPDATE categories SET sort_order = ? WHERE id = ?', [index, catId]);
    });
  });

  const ensureFloatingCompanionInitialized = (): void => {
    const count = executeQuery<{ cnt: number }>('SELECT COUNT(*) as cnt FROM floating_companion');
    if (count[0]?.cnt === 0) {
      executeInsert('INSERT INTO floating_companion (id, is_expanded, is_minimized, last_active_note_id, position_x, position_y) VALUES (1, 0, 0, NULL, 16, 200)');
    }
  };

  ipcMain.handle('floatingCompanion:getState', () => {
    ensureFloatingCompanionInitialized();
    const rows = executeQuery<any>('SELECT * FROM floating_companion WHERE id = 1');
    if (rows.length === 0) {
      return { isExpanded: false, isMinimized: false, lastActiveNoteId: null, positionX: 16, positionY: 200 };
    }
    return {
      isExpanded: rows[0].is_expanded === 1,
      isMinimized: rows[0].is_minimized === 1,
      lastActiveNoteId: rows[0].last_active_note_id,
      positionX: rows[0].position_x,
      positionY: rows[0].position_y,
    };
  });

  ipcMain.handle('floatingCompanion:setExpanded', (_, isExpanded: boolean) => {
    ensureFloatingCompanionInitialized();
    executeUpdate('UPDATE floating_companion SET is_expanded = ? WHERE id = 1', [isExpanded ? 1 : 0]);
    return (ipcMain as any).invoke('floatingCompanion:getState');
  });

  ipcMain.handle('floatingCompanion:setMinimized', (_, isMinimized: boolean) => {
    ensureFloatingCompanionInitialized();
    executeUpdate('UPDATE floating_companion SET is_minimized = ? WHERE id = 1', [isMinimized ? 1 : 0]);
    return (ipcMain as any).invoke('floatingCompanion:getState');
  });

  ipcMain.handle('floatingCompanion:setPosition', (_, positionX: number, positionY: number) => {
    ensureFloatingCompanionInitialized();
    executeUpdate('UPDATE floating_companion SET position_x = ?, position_y = ? WHERE id = 1',
      [positionX, positionY]);
    return (ipcMain as any).invoke('floatingCompanion:getState');
  });

  ipcMain.handle('floatingCompanion:setLastActiveNote', (_, noteId: string | null) => {
    ensureFloatingCompanionInitialized();
    executeUpdate('UPDATE floating_companion SET last_active_note_id = ? WHERE id = 1', [noteId]);
    return (ipcMain as any).invoke('floatingCompanion:getState');
  });

  ipcMain.handle('floatingCompanion:updateState', (_, updates: Partial<FloatingCompanionState>) => {
    ensureFloatingCompanionInitialized();
    const current = (ipcMain as any).invoke('floatingCompanion:getState');
    const newState = { ...current, ...updates };
    executeUpdate(
      'UPDATE floating_companion SET is_expanded = ?, is_minimized = ?, last_active_note_id = ?, position_x = ?, position_y = ? WHERE id = 1',
      [newState.isExpanded ? 1 : 0, newState.isMinimized ? 1 : 0, newState.lastActiveNoteId, newState.positionX, newState.positionY]
    );
    return (ipcMain as any).invoke('floatingCompanion:getState');
  });

  ipcMain.handle('floatingCompanion:reset', () => {
    ensureFloatingCompanionInitialized();
    executeUpdate('UPDATE floating_companion SET is_expanded = 0, is_minimized = 0, last_active_note_id = NULL, position_x = 16, position_y = 200 WHERE id = 1');
    return (ipcMain as any).invoke('floatingCompanion:getState');
  });

  ipcMain.handle('settings:get', (_, key: string, defaultValue: any) => {
    const rows = executeQuery<{ value: string }>('SELECT value FROM settings WHERE key = ?', [key]);
    if (rows.length === 0) return defaultValue;
    try {
      return JSON.parse(rows[0].value);
    } catch {
      return defaultValue;
    }
  });

  ipcMain.handle('settings:set', (_, key: string, value: any) => {
    executeInsert('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [key, JSON.stringify(value)]);
  });

  ipcMain.handle('settings:getAll', () => {
    const rows = executeQuery<{ key: string; value: string }>('SELECT * FROM settings');
    const settings: Record<string, any> = {};
    rows.forEach(row => {
      try {
        settings[row.key] = JSON.parse(row.value);
      } catch {
        settings[row.key] = row.value;
      }
    });
    return settings;
  });

  ipcMain.handle('notes:export', () => {
    const notes = executeQuery<NoteRow>('SELECT * FROM notes ORDER BY updated_at DESC');
    const stickyNotes = executeQuery<StickyNoteRow>('SELECT * FROM sticky_notes ORDER BY created_at DESC');
    
    let content = '# NOVE Mobile Notes Export\n';
    content += `Exported on: ${new Date().toLocaleString()}\n`;
    content += '='.repeat(50) + '\n\n';

    const mappedNotes = notes.map(mapRowToNote);
    mappedNotes.forEach((note, index) => {
      content += `## ${index + 1}. ${note.title || 'Untitled'}\n`;
      content += `- Category: ${note.category || 'None'}\n`;
      content += `- Pinned: ${note.isPinned ? 'Yes' : 'No'}\n`;
      content += `- Favorite: ${note.isFavorite ? 'Yes' : 'No'}\n`;
      content += `- Created: ${new Date(note.createdAt).toLocaleString()}\n`;
      content += `- Updated: ${new Date(note.updatedAt).toLocaleString()}\n`;
      content += `- Words: ${note.wordCount}, Characters: ${note.charCount}\n\n`;
      content += note.content + '\n';
      content += '-'.repeat(50) + '\n\n';
    });

    content += '\n# Sticky Notes\n';
    content += '='.repeat(50) + '\n\n';

    stickyNotes.forEach((note, index) => {
      content += `[${note.color.toUpperCase()}] ${note.title || 'Untitled'}\n`;
      content += note.content + '\n';
      content += '-'.repeat(30) + '\n\n';
    });

    return content;
  });
};
