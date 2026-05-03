import { executeQuery, executeUpdate } from '../database';
import { AppSettings } from '../types';

const DEFAULT_SETTINGS: AppSettings = {
  floatingCompanionEnabled: true,
  theme: 'system',
  lastSyncTimestamp: null,
};

export class SettingsService {
  private static getSetting<T>(key: string, defaultValue: T): T {
    const rows = executeQuery<{ value: string }>('SELECT value FROM settings WHERE key = ?', [key]);
    
    if (rows.length === 0) {
      return defaultValue;
    }

    try {
      return JSON.parse(rows[0].value) as T;
    } catch {
      return defaultValue;
    }
  }

  private static setSetting<T>(key: string, value: T): void {
    const jsonValue = JSON.stringify(value);
    executeUpdate(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      [key, jsonValue]
    );
  }

  static getAllSettings(): AppSettings {
    return {
      floatingCompanionEnabled: this.getSetting('floatingCompanionEnabled', DEFAULT_SETTINGS.floatingCompanionEnabled),
      theme: this.getSetting('theme', DEFAULT_SETTINGS.theme),
      lastSyncTimestamp: this.getSetting('lastSyncTimestamp', DEFAULT_SETTINGS.lastSyncTimestamp),
    };
  }

  static updateSettings(updates: Partial<AppSettings>): AppSettings {
    if (updates.floatingCompanionEnabled !== undefined) {
      this.setSetting('floatingCompanionEnabled', updates.floatingCompanionEnabled);
    }
    if (updates.theme !== undefined) {
      this.setSetting('theme', updates.theme);
    }
    if (updates.lastSyncTimestamp !== undefined) {
      this.setSetting('lastSyncTimestamp', updates.lastSyncTimestamp);
    }
    return this.getAllSettings();
  }

  static getFloatingCompanionEnabled(): boolean {
    return this.getSetting('floatingCompanionEnabled', DEFAULT_SETTINGS.floatingCompanionEnabled);
  }

  static setFloatingCompanionEnabled(enabled: boolean): void {
    this.setSetting('floatingCompanionEnabled', enabled);
  }

  static getTheme(): 'light' | 'dark' | 'system' {
    return this.getSetting('theme', DEFAULT_SETTINGS.theme);
  }

  static setTheme(theme: 'light' | 'dark' | 'system'): void {
    this.setSetting('theme', theme);
  }

  static resetSettings(): AppSettings {
    Object.entries(DEFAULT_SETTINGS).forEach(([key, value]) => {
      this.setSetting(key, value);
    });
    return DEFAULT_SETTINGS;
  }
}
