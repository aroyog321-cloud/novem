import Database from 'better-sqlite3';
import path from 'path';
import { app } from 'electron';
import fs from 'fs';

const DATABASE_NAME = 'nove_desktop.db';

let db: Database.Database | null = null;

export const getDatabase = (): Database.Database => {
  if (!db) {
    throw new Error('Database not initialized. Call initDatabase() first.');
  }
  return db;
};

export const initDatabase = (): Database.Database => {
  if (db) {
    return db;
  }

  const userDataPath = app.getPath('userData');
  if (!fs.existsSync(userDataPath)) {
    fs.mkdirSync(userDataPath, { recursive: true });
  }

  const dbPath = path.join(userDataPath, DATABASE_NAME);
  console.log('Database path:', dbPath);

  try {
    db = new Database(dbPath);
    db.pragma('journal_mode = WAL');
    console.log('Database connected successfully');
    runMigrations();
    return db;
  } catch (err) {
    console.error('Database connection failed:', err);
    throw err;
  }
};

export const closeDatabase = (): void => {
  if (db) {
    db.close();
    db = null;
  }
};

const runMigrations = (): void => {
  if (!db) return;

  db.exec(`
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

  db.exec(`
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

  db.exec(`
    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      color TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0
    );
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS floating_companion (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      is_expanded INTEGER DEFAULT 0,
      is_minimized INTEGER DEFAULT 0,
      last_active_note_id TEXT,
      position_x REAL DEFAULT 16,
      position_y REAL DEFAULT 200
    );
  `);

  db.exec(`CREATE INDEX IF NOT EXISTS idx_notes_category ON notes(category);`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON notes(is_pinned);`);
  db.exec(`CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);`);
};

export const executeQuery = <T>(sql: string, params: (string | number | null)[] = []): T[] => {
  const database = getDatabase();
  const stmt = database.prepare(sql);
  return stmt.all(...params) as T[];
};

export const executeInsert = (sql: string, params: (string | number | null)[] = []): number => {
  const database = getDatabase();
  const stmt = database.prepare(sql);
  const result = stmt.run(...params);
  return result.lastInsertRowid as number;
};

export const executeUpdate = (sql: string, params: (string | number | null)[] = []): number => {
  const database = getDatabase();
  const stmt = database.prepare(sql);
  const result = stmt.run(...params);
  return result.changes;
};
