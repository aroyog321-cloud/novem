"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.executeUpdate = exports.executeInsert = exports.executeQuery = exports.closeDatabase = exports.initDatabase = exports.getDatabase = void 0;
const better_sqlite3_1 = __importDefault(require("better-sqlite3"));
const path_1 = __importDefault(require("path"));
const electron_1 = require("electron");
const fs_1 = __importDefault(require("fs"));
const DATABASE_NAME = 'nove_desktop.db';
let db = null;
const getDatabase = () => {
    if (!db) {
        throw new Error('Database not initialized. Call initDatabase() first.');
    }
    return db;
};
exports.getDatabase = getDatabase;
const initDatabase = () => {
    if (db) {
        return db;
    }
    const userDataPath = electron_1.app.getPath('userData');
    if (!fs_1.default.existsSync(userDataPath)) {
        fs_1.default.mkdirSync(userDataPath, { recursive: true });
    }
    const dbPath = path_1.default.join(userDataPath, DATABASE_NAME);
    console.log('Database path:', dbPath);
    try {
        db = new better_sqlite3_1.default(dbPath);
        db.pragma('journal_mode = WAL');
        console.log('Database connected successfully');
        runMigrations();
        return db;
    }
    catch (err) {
        console.error('Database connection failed:', err);
        throw err;
    }
};
exports.initDatabase = initDatabase;
const closeDatabase = () => {
    if (db) {
        db.close();
        db = null;
    }
};
exports.closeDatabase = closeDatabase;
const runMigrations = () => {
    if (!db)
        return;
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
const executeQuery = (sql, params = []) => {
    const database = (0, exports.getDatabase)();
    const stmt = database.prepare(sql);
    return stmt.all(...params);
};
exports.executeQuery = executeQuery;
const executeInsert = (sql, params = []) => {
    const database = (0, exports.getDatabase)();
    const stmt = database.prepare(sql);
    const result = stmt.run(...params);
    return result.lastInsertRowid;
};
exports.executeInsert = executeInsert;
const executeUpdate = (sql, params = []) => {
    const database = (0, exports.getDatabase)();
    const stmt = database.prepare(sql);
    const result = stmt.run(...params);
    return result.changes;
};
exports.executeUpdate = executeUpdate;
