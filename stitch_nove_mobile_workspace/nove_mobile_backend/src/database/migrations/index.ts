import { QuickSQLiteConnection } from '../index';

export const MIGRATIONS = [
  {
    version: 1,
    up: (db: QuickSQLiteConnection) => {
      db.execute(`
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
      `);

      db.execute(`
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
      `);

      db.execute(`
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color TEXT NOT NULL,
          sort_order INTEGER DEFAULT 0
        );
      `);

      db.execute(`
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
      `);

      db.execute(`
        CREATE TABLE IF NOT EXISTS floating_companion (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          is_expanded INTEGER DEFAULT 0,
          is_minimized INTEGER DEFAULT 0,
          last_active_note_id TEXT,
          position_x REAL DEFAULT 16,
          position_y REAL DEFAULT 200
        );
      `);

      db.execute(`
        CREATE INDEX IF NOT EXISTS idx_notes_category ON notes(category);
      `);

      db.execute(`
        CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON notes(is_pinned);
      `);

      db.execute(`
        CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);
      `);
    },
  },
];

export const runMigrations = (db: QuickSQLiteConnection, currentVersion: number): number => {
  const targetVersion = MIGRATIONS.length;
  
  if (currentVersion >= targetVersion) {
    return currentVersion;
  }

  for (let i = currentVersion; i < targetVersion; i++) {
    MIGRATIONS[i].up(db);
  }

  return targetVersion;
};
