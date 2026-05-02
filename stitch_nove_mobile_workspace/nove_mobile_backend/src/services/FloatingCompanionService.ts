import { executeQuery, executeUpdate } from '../database';
import { FloatingCompanionState } from '../types';

interface FloatingCompanionRow {
  id: number;
  is_expanded: number;
  is_minimized: number;
  last_active_note_id: string | null;
  position_x: number;
  position_y: number;
}

const DEFAULT_STATE: FloatingCompanionState = {
  isExpanded: false,
  isMinimized: false,
  lastActiveNoteId: null,
  positionX: 16,
  positionY: 200,
};

export class FloatingCompanionService {
  private static ensureInitialized(): void {
    const count = executeQuery<{ cnt: number }>('SELECT COUNT(*) as cnt FROM floating_companion');
    if (count[0]?.cnt === 0) {
      executeUpdate(
        `INSERT INTO floating_companion (id, is_expanded, is_minimized, last_active_note_id, position_x, position_y)
         VALUES (1, 0, 0, NULL, 16, 200)`
      );
    }
  }

  static getState(): FloatingCompanionState {
    this.ensureInitialized();
    
    const rows = executeQuery<FloatingCompanionRow>('SELECT * FROM floating_companion WHERE id = 1');
    
    if (rows.length === 0) {
      return DEFAULT_STATE;
    }

    return {
      isExpanded: rows[0].is_expanded === 1,
      isMinimized: rows[0].is_minimized === 1,
      lastActiveNoteId: rows[0].last_active_note_id,
      positionX: rows[0].position_x,
      positionY: rows[0].position_y,
    };
  }

  static setExpanded(isExpanded: boolean): FloatingCompanionState {
    this.ensureInitialized();
    executeUpdate('UPDATE floating_companion SET is_expanded = ? WHERE id = 1', [isExpanded ? 1 : 0]);
    return this.getState();
  }

  static setMinimized(isMinimized: boolean): FloatingCompanionState {
    this.ensureInitialized();
    executeUpdate('UPDATE floating_companion SET is_minimized = ? WHERE id = 1', [isMinimized ? 1 : 0]);
    return this.getState();
  }

  static setLastActiveNoteId(noteId: string | null): FloatingCompanionState {
    this.ensureInitialized();
    executeUpdate('UPDATE floating_companion SET last_active_note_id = ? WHERE id = 1', [noteId]);
    return this.getState();
  }

  static setPosition(positionX: number, positionY: number): FloatingCompanionState {
    this.ensureInitialized();
    executeUpdate(
      'UPDATE floating_companion SET position_x = ?, position_y = ? WHERE id = 1',
      [positionX, positionY]
    );
    return this.getState();
  }

  static updateState(updates: Partial<FloatingCompanionState>): FloatingCompanionState {
    this.ensureInitialized();
    
    const current = this.getState();
    const newState = { ...current, ...updates };

    executeUpdate(
      `UPDATE floating_companion 
       SET is_expanded = ?, is_minimized = ?, last_active_note_id = ?, position_x = ?, position_y = ?
       WHERE id = 1`,
      [
        newState.isExpanded ? 1 : 0,
        newState.isMinimized ? 1 : 0,
        newState.lastActiveNoteId,
        newState.positionX,
        newState.positionY,
      ]
    );

    return this.getState();
  }

  static expand(): FloatingCompanionState {
    return this.setExpanded(true);
  }

  static collapse(): FloatingCompanionState {
    return this.setExpanded(false);
  }

  static minimize(): FloatingCompanionState {
    return this.setMinimized(true);
  }

  static restore(): FloatingCompanionState {
    return this.setMinimized(false);
  }

  static reset(): FloatingCompanionState {
    this.ensureInitialized();
    executeUpdate(
      `UPDATE floating_companion 
       SET is_expanded = 0, is_minimized = 0, last_active_note_id = NULL, position_x = 16, position_y = 200
       WHERE id = 1`
    );
    return this.getState();
  }
}
