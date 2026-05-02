import { useState, useEffect, useCallback } from 'react';
import { initDatabase } from '../database';
import { NoteService, StickyNoteService, CategoryService, FloatingCompanionService } from '../services';
import { Note, StickyNote, Category, FloatingCompanionState, StickyColor } from '../types';

export const useDatabase = () => {
  const [isReady, setIsReady] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    initializeDatabase();
  }, []);

  const initializeDatabase = async () => {
    try {
      await initDatabase();
      setIsReady(true);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Database initialization failed'));
    }
  };

  return { isReady, error };
};

export const useNotes = () => {
  const [notes, setNotes] = useState<Note[]>([]);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(() => {
    setNotes(NoteService.getAllNotes());
    setLoading(false);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const createNote = useCallback((content: string, category?: string | null, colorLabel?: string) => {
    const note = NoteService.createNote(content, category, colorLabel);
    refresh();
    return note;
  }, [refresh]);

  const updateNote = useCallback((id: string, updates: Partial<Pick<Note, 'content' | 'category' | 'colorLabel' | 'isPinned' | 'isFavorite'>>) => {
    const updated = NoteService.updateNote(id, updates);
    refresh();
    return updated;
  }, [refresh]);

  const deleteNote = useCallback((id: string) => {
    const success = NoteService.deleteNote(id);
    refresh();
    return success;
  }, [refresh]);

  const togglePin = useCallback((id: string) => {
    const updated = NoteService.togglePin(id);
    refresh();
    return updated;
  }, [refresh]);

  const toggleFavorite = useCallback((id: string) => {
    const updated = NoteService.toggleFavorite(id);
    refresh();
    return updated;
  }, [refresh]);

  const searchNotes = useCallback((query: string) => {
    return NoteService.searchNotes(query);
  }, []);

  const getNotesByCategory = useCallback((category: string) => {
    return NoteService.getNotesByCategory(category);
  }, []);

  return {
    notes,
    loading,
    refresh,
    createNote,
    updateNote,
    deleteNote,
    togglePin,
    toggleFavorite,
    searchNotes,
    getNotesByCategory,
  };
};

export const useStickyNotes = () => {
  const [stickyNotes, setStickyNotes] = useState<StickyNote[]>([]);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(() => {
    setStickyNotes(StickyNoteService.getAllStickyNotes());
    setLoading(false);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const createStickyNote = useCallback((
    title: string,
    content: string,
    color?: StickyColor,
    positionX?: number,
    positionY?: number
  ) => {
    const note = StickyNoteService.createStickyNote(title, content, color, positionX, positionY);
    refresh();
    return note;
  }, [refresh]);

  const updateStickyNote = useCallback((
    id: string,
    updates: Partial<Pick<StickyNote, 'title' | 'content' | 'color' | 'positionX' | 'positionY'>>
  ) => {
    const updated = StickyNoteService.updateStickyNote(id, updates);
    refresh();
    return updated;
  }, [refresh]);

  const deleteStickyNote = useCallback((id: string) => {
    const success = StickyNoteService.deleteStickyNote(id);
    refresh();
    return success;
  }, [refresh]);

  const updatePosition = useCallback((id: string, x: number, y: number) => {
    const updated = StickyNoteService.updateStickyNotePosition(id, x, y);
    refresh();
    return updated;
  }, [refresh]);

  return {
    stickyNotes,
    loading,
    refresh,
    createStickyNote,
    updateStickyNote,
    deleteStickyNote,
    updatePosition,
  };
};

export const useFloatingCompanion = () => {
  const [state, setState] = useState<FloatingCompanionState>(FloatingCompanionService.getState());
  const [isExpanded, setIsExpanded] = useState(false);
  const [isMinimized, setIsMinimized] = useState(false);

  const refresh = useCallback(() => {
    const newState = FloatingCompanionService.getState();
    setState(newState);
    setIsExpanded(newState.isExpanded);
    setIsMinimized(newState.isMinimized);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const expand = useCallback(() => {
    FloatingCompanionService.expand();
    refresh();
  }, [refresh]);

  const collapse = useCallback(() => {
    FloatingCompanionService.collapse();
    refresh();
  }, [refresh]);

  const minimize = useCallback(() => {
    FloatingCompanionService.minimize();
    refresh();
  }, [refresh]);

  const restore = useCallback(() => {
    FloatingCompanionService.restore();
    refresh();
  }, [refresh]);

  const toggleExpanded = useCallback(() => {
    if (isExpanded) {
      collapse();
    } else {
      expand();
    }
  }, [isExpanded, expand, collapse]);

  const setPosition = useCallback((x: number, y: number) => {
    FloatingCompanionService.setPosition(x, y);
    refresh();
  }, [refresh]);

  const setLastActiveNote = useCallback((noteId: string | null) => {
    FloatingCompanionService.setLastActiveNoteId(noteId);
    refresh();
  }, [refresh]);

  const updateState = useCallback((updates: Partial<FloatingCompanionState>) => {
    FloatingCompanionService.updateState(updates);
    refresh();
  }, [refresh]);

  return {
    state,
    isExpanded,
    isMinimized,
    expand,
    collapse,
    minimize,
    restore,
    toggleExpanded,
    setPosition,
    setLastActiveNote,
    updateState,
    refresh,
  };
};

export const useCategories = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(() => {
    setCategories(CategoryService.getAllCategories());
    setLoading(false);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const createCategory = useCallback((name: string, color: string) => {
    const category = CategoryService.createCategory(name, color);
    refresh();
    return category;
  }, [refresh]);

  const updateCategory = useCallback((id: string, updates: Partial<Pick<Category, 'name' | 'color' | 'order'>>) => {
    const updated = CategoryService.updateCategory(id, updates);
    refresh();
    return updated;
  }, [refresh]);

  const deleteCategory = useCallback((id: string) => {
    const success = CategoryService.deleteCategory(id);
    refresh();
    return success;
  }, [refresh]);

  const reorderCategories = useCallback((categoryIds: string[]) => {
    CategoryService.reorderCategories(categoryIds);
    refresh();
  }, [refresh]);

  return {
    categories,
    loading,
    refresh,
    createCategory,
    updateCategory,
    deleteCategory,
    reorderCategories,
  };
};
