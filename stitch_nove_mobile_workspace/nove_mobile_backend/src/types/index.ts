export interface Note {
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

export interface StickyNote {
  id: string;
  title: string;
  content: string;
  color: StickyColor;
  positionX: number;
  positionY: number;
  createdAt: number;
  updatedAt: number;
}

export type StickyColor = 'yellow' | 'pink' | 'green' | 'blue';

export interface Category {
  id: string;
  name: string;
  color: string;
  order: number;
}

export interface FloatingCompanionState {
  isExpanded: boolean;
  isMinimized: boolean;
  lastActiveNoteId: string | null;
  positionX: number;
  positionY: number;
}

export interface AppSettings {
  floatingCompanionEnabled: boolean;
  theme: 'light' | 'dark' | 'system';
  lastSyncTimestamp: number | null;
}

export interface ExportData {
  version: number;
  exportedAt: number;
  notes: Note[];
  stickyNotes: StickyNote[];
  categories: Category[];
}
