import { executeQuery, executeUpdate } from '../database';
import { StickyNote, StickyColor } from '../types';

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

const mapRowToStickyNote = (row: StickyNoteRow): StickyNote => ({
  id: row.id,
  title: row.title,
  content: row.content,
  color: row.color as StickyColor,
  positionX: row.position_x,
  positionY: row.position_y,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

export class StickyNoteService {
  static getAllStickyNotes(): StickyNote[] {
    const rows = executeQuery<StickyNoteRow>(
      'SELECT * FROM sticky_notes ORDER BY created_at DESC'
    );
    return rows.map(mapRowToStickyNote);
  }

  static getStickyNoteById(id: string): StickyNote | null {
    const rows = executeQuery<StickyNoteRow>(
      'SELECT * FROM sticky_notes WHERE id = ?',
      [id]
    );
    return rows.length > 0 ? mapRowToStickyNote(rows[0]) : null;
  }

  static getStickyNotesByColor(color: StickyColor): StickyNote[] {
    const rows = executeQuery<StickyNoteRow>(
      'SELECT * FROM sticky_notes WHERE color = ? ORDER BY created_at DESC',
      [color]
    );
    return rows.map(mapRowToStickyNote);
  }

  static createStickyNote(
    title: string,
    content: string,
    color: StickyColor = 'yellow',
    positionX: number = 0,
    positionY: number = 0
  ): StickyNote {
    const now = Date.now();
    const id = `sticky_${now}_${Math.random().toString(36).substr(2, 9)}`;

    executeUpdate(
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
  }

  static updateStickyNote(
    id: string,
    updates: Partial<Pick<StickyNote, 'title' | 'content' | 'color' | 'positionX' | 'positionY'>>
  ): StickyNote | null {
    const existing = this.getStickyNoteById(id);
    if (!existing) return null;

    const now = Date.now();

    const title = updates.title ?? existing.title;
    const content = updates.content ?? existing.content;
    const color = updates.color ?? existing.color;
    const positionX = updates.positionX ?? existing.positionX;
    const positionY = updates.positionY ?? existing.positionY;

    executeUpdate(
      `UPDATE sticky_notes SET title = ?, content = ?, color = ?, position_x = ?, position_y = ?, updated_at = ?
       WHERE id = ?`,
      [title, content, color, positionX, positionY, now, id]
    );

    return this.getStickyNoteById(id);
  }

  static updateStickyNotePosition(id: string, positionX: number, positionY: number): StickyNote | null {
    return this.updateStickyNote(id, { positionX, positionY });
  }

  static updateStickyNoteContent(id: string, content: string): StickyNote | null {
    return this.updateStickyNote(id, { content });
  }

  static updateStickyNoteTitle(id: string, title: string): StickyNote | null {
    return this.updateStickyNote(id, { title });
  }

  static deleteStickyNote(id: string): boolean {
    const affected = executeUpdate('DELETE FROM sticky_notes WHERE id = ?', [id]);
    return affected > 0;
  }

  static getStickyNotesCount(): number {
    const result = executeQuery<{ count: number }>('SELECT COUNT(*) as count FROM sticky_notes');
    return result[0]?.count ?? 0;
  }

  static clearAllStickyNotes(): number {
    return executeUpdate('DELETE FROM sticky_notes');
  }
}
