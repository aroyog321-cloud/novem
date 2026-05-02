import { Note } from '../../types';

export const NoteModel: Note = {
  id: '',
  title: '',
  content: '',
  category: null,
  colorLabel: '#FFFFFF',
  isPinned: false,
  isFavorite: false,
  createdAt: Date.now(),
  updatedAt: Date.now(),
  wordCount: 0,
  charCount: 0,
  readTimeMinutes: 0,
};

export const CREATE_NOTES_TABLE = `
  CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT,
    color_label TEXT DEFAULT '#FFFFFF',
    is_pinned INTEGER DEFAULT 0,
    is_favorite INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    word_count INTEGER DEFAULT 0,
    char_count INTEGER DEFAULT 0,
    read_time_minutes REAL DEFAULT 0
  );
`;

export const CREATE_STICKY_NOTES_TABLE = `
  CREATE TABLE IF NOT EXISTS sticky_notes (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    color TEXT DEFAULT 'yellow',
    position_x REAL DEFAULT 0,
    position_y REAL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  );
`;

export const CREATE_CATEGORIES_TABLE = `
  CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0
  );
`;

export const CREATE_SETTINGS_TABLE = `
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  );
`;

export const CREATE_FLOATING_COMPANION_TABLE = `
  CREATE TABLE IF NOT EXISTS floating_companion (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    is_expanded INTEGER DEFAULT 0,
    is_minimized INTEGER DEFAULT 0,
    last_active_note_id TEXT,
    position_x REAL DEFAULT 16,
    position_y REAL DEFAULT 200
  );
`;
