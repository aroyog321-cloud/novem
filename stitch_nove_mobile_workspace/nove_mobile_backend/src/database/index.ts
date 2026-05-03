import { Platform } from 'react-native';
import { runMigrations } from './migrations';

let open: any = null;
if (Platform.OS !== 'web') {
  try {
    const QuickSQLite = require('react-native-quick-sqlite');
    open = QuickSQLite.open;
  } catch (e) {
    console.warn('Could not load react-native-quick-sqlite');
  }
}

const DATABASE_NAME = 'nove_mobile.db';
const DATABASE_VERSION_KEY = 'database_version';

export type QuickSQLiteConnection = any;

let dbInstance: QuickSQLiteConnection | null = null;

// Simple Web Mock for UI rendering
class WebMockDB {
  tables: Record<string, any[]> = {
    notes: [],
    sticky_notes: [],
    categories: [],
    settings: [],
    floating_companion: []
  };

  execute(query: string, params: any[] = []): any {
    const q = query.trim().toUpperCase();
    if (q.startsWith('SELECT * FROM NOTES')) {
      return { rows: { length: this.tables.notes.length, item: (i: number) => this.tables.notes[i] } };
    }
    if (q.startsWith('SELECT COUNT')) {
      return { rows: { length: 1, item: () => ({ count: this.tables.notes.length }) } };
    }
    if (q.startsWith('INSERT INTO NOTES')) {
      const id = params[0] || 'mock_id';
      this.tables.notes.unshift({
        id: params[0], title: params[1], content: params[2], category: params[3], color_label: params[4],
        is_pinned: params[5], is_favorite: params[6], created_at: params[7], updated_at: params[8],
        word_count: params[9], char_count: params[10], read_time_minutes: params[11]
      });
      return { insertId: 1, rowsAffected: 1 };
    }
    if (q.startsWith('UPDATE NOTES')) {
      // Mock update
      return { rowsAffected: 1 };
    }
    if (q.startsWith('DELETE FROM NOTES')) {
      this.tables.notes = this.tables.notes.filter(n => n.id !== params[0]);
      return { rowsAffected: 1 };
    }
    if (q.startsWith('SELECT VALUE FROM SETTINGS')) {
      return { rows: { length: 0, item: () => ({}) } };
    }
    
    return { rows: { length: 0, item: () => ({}) }, rowsAffected: 0 };
  }
  close() {}
}

export const getDatabase = (): QuickSQLiteConnection => {
  if (!dbInstance) {
    throw new Error('Database not initialized. Call initDatabase() first.');
  }
  return dbInstance;
};

export const initDatabase = async (): Promise<QuickSQLiteConnection> => {
  if (dbInstance) {
    return dbInstance;
  }

  try {
    if (Platform.OS === 'web' || !open) {
      dbInstance = new WebMockDB();
      return dbInstance;
    }

    dbInstance = open({ name: DATABASE_NAME });
    
    const version = getStoredVersion();
    const newVersion = runMigrations(dbInstance, version);
    
    if (version !== newVersion) {
      setStoredVersion(newVersion);
    }

    dbInstance.execute(`
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    `);

    return dbInstance;
  } catch (error) {
    console.error('Failed to initialize database:', error);
    throw error;
  }
};

export const closeDatabase = (): void => {
  if (dbInstance) {
    dbInstance.close();
    dbInstance = null;
  }
};

const getStoredVersion = (): number => {
  if (!dbInstance) return 0;
  
  if (Platform.OS === 'web') return 1;

  try {
    const result = dbInstance.execute(
      `SELECT value FROM settings WHERE key = '${DATABASE_VERSION_KEY}'`
    );
    
    if (result.rows && result.rows.length > 0) {
      return parseInt(result.rows.item(0).value, 10) || 0;
    }
  } catch {
    return 0;
  }
  return 0;
};

const setStoredVersion = (version: number): void => {
  if (!dbInstance || Platform.OS === 'web') return;
  
  dbInstance.execute(
    `INSERT OR REPLACE INTO settings (key, value) VALUES ('${DATABASE_VERSION_KEY}', '${version}')`
  );
};

export const executeQuery = <T>(
  query: string,
  params: (string | number | null)[] = []
): T[] => {
  const db = getDatabase();
  const result = db.execute(query, params);
  
  const rows: T[] = [];
  if (result.rows && result.rows.length !== undefined) {
    for (let i = 0; i < result.rows.length; i++) {
      rows.push(result.rows.item(i) as T);
    }
  }
  return rows;
};

export const executeInsert = (
  query: string,
  params: (string | number | null)[] = []
): number => {
  const db = getDatabase();
  const result = db.execute(query, params);
  return result.insertId ?? -1;
};

export const executeUpdate = (
  query: string,
  params: (string | number | null)[] = []
): number => {
  const db = getDatabase();
  const result = db.execute(query, params);
  return result.rowsAffected ?? 0;
};
