"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupIpcHandlers = void 0;
const electron_1 = require("electron");
const database_1 = require("./database");
const mapRowToNote = (row) => ({
    id: row.id,
    title: row.title,
    content: row.content,
    category: row.category,
    colorLabel: row.color_label,
    isPinned: row.is_pinned === 1,
    isFavorite: row.is_favorite === 1,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    wordCount: row.word_count,
    charCount: row.char_count,
    readTimeMinutes: row.read_time_minutes,
});
const mapRowToStickyNote = (row) => ({
    id: row.id,
    title: row.title,
    content: row.content,
    color: row.color,
    positionX: row.position_x,
    positionY: row.position_y,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
});
const mapRowToCategory = (row) => ({
    id: row.id,
    name: row.name,
    color: row.color,
    order: row.sort_order,
});
const calculateReadTime = (content) => {
    const wordCount = content.trim().split(/\s+/).filter(Boolean).length;
    return Math.max(1, Math.ceil(wordCount / 200));
};
const calculateWordCount = (content) => {
    return content.trim().split(/\s+/).filter(Boolean).length;
};
const extractTitle = (content) => {
    const firstLine = content.split('\n')[0]?.trim() || 'Untitled';
    return firstLine.length > 100 ? firstLine.substring(0, 97) + '...' : firstLine;
};
const generateId = () => `note_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
const generateStickyId = () => `sticky_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
const generateCatId = () => `cat_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
const setupIpcHandlers = () => {
    electron_1.ipcMain.handle('notes:getAll', () => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes ORDER BY is_pinned DESC, updated_at DESC');
        return rows.map(mapRowToNote);
    });
    electron_1.ipcMain.handle('notes:getById', (_, id) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes WHERE id = ?', [id]);
        return rows.length > 0 ? mapRowToNote(rows[0]) : null;
    });
    electron_1.ipcMain.handle('notes:getByCategory', (_, category) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes WHERE category = ? ORDER BY is_pinned DESC, updated_at DESC', [category]);
        return rows.map(mapRowToNote);
    });
    electron_1.ipcMain.handle('notes:getPinned', () => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes WHERE is_pinned = 1 ORDER BY updated_at DESC');
        return rows.map(mapRowToNote);
    });
    electron_1.ipcMain.handle('notes:getFavorites', () => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes WHERE is_favorite = 1 ORDER BY updated_at DESC');
        return rows.map(mapRowToNote);
    });
    electron_1.ipcMain.handle('notes:search', (_, query) => {
        const searchTerm = `%${query}%`;
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes WHERE title LIKE ? OR content LIKE ? ORDER BY updated_at DESC', [searchTerm, searchTerm]);
        return rows.map(mapRowToNote);
    });
    electron_1.ipcMain.handle('notes:create', (_, content, category, colorLabel) => {
        const now = Date.now();
        const id = generateId();
        const title = extractTitle(content);
        const wordCount = calculateWordCount(content);
        const charCount = content.length;
        const readTimeMinutes = calculateReadTime(content);
        (0, database_1.executeInsert)(`INSERT INTO notes (id, title, content, category, color_label, is_pinned, is_favorite, created_at, updated_at, word_count, char_count, read_time_minutes)
       VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?, ?)`, [id, title, content, category, colorLabel, now, now, wordCount, charCount, readTimeMinutes]);
        return {
            id,
            title,
            content,
            category,
            colorLabel,
            isPinned: false,
            isFavorite: false,
            createdAt: now,
            updatedAt: now,
            wordCount,
            charCount,
            readTimeMinutes,
        };
    });
    electron_1.ipcMain.handle('notes:update', (_, id, updates) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes WHERE id = ?', [id]);
        if (rows.length === 0)
            return null;
        const existing = mapRowToNote(rows[0]);
        const now = Date.now();
        const content = updates.content ?? existing.content;
        const title = extractTitle(content);
        const wordCount = calculateWordCount(content);
        const charCount = content.length;
        const readTimeMinutes = calculateReadTime(content);
        (0, database_1.executeUpdate)(`UPDATE notes SET title = ?, content = ?, category = ?, color_label = ?, is_pinned = ?, is_favorite = ?, updated_at = ?, word_count = ?, char_count = ?, read_time_minutes = ?
       WHERE id = ?`, [
            title,
            content,
            updates.category !== undefined ? updates.category : existing.category,
            updates.colorLabel ?? existing.colorLabel,
            updates.isPinned ?? existing.isPinned ? 1 : 0,
            updates.isFavorite ?? existing.isFavorite ? 1 : 0,
            now,
            wordCount,
            charCount,
            readTimeMinutes,
            id,
        ]);
        return mapRowToNote((0, database_1.executeQuery)('SELECT * FROM notes WHERE id = ?', [id])[0]);
    });
    electron_1.ipcMain.handle('notes:delete', (_, id) => {
        return (0, database_1.executeUpdate)('DELETE FROM notes WHERE id = ?', [id]) > 0;
    });
    electron_1.ipcMain.handle('notes:togglePin', (_, id) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes WHERE id = ?', [id]);
        if (rows.length === 0)
            return null;
        const note = mapRowToNote(rows[0]);
        (0, database_1.executeUpdate)('UPDATE notes SET is_pinned = ? WHERE id = ?', [note.isPinned ? 0 : 1, id]);
        return mapRowToNote((0, database_1.executeQuery)('SELECT * FROM notes WHERE id = ?', [id])[0]);
    });
    electron_1.ipcMain.handle('notes:toggleFavorite', (_, id) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM notes WHERE id = ?', [id]);
        if (rows.length === 0)
            return null;
        const note = mapRowToNote(rows[0]);
        (0, database_1.executeUpdate)('UPDATE notes SET is_favorite = ? WHERE id = ?', [note.isFavorite ? 0 : 1, id]);
        return mapRowToNote((0, database_1.executeQuery)('SELECT * FROM notes WHERE id = ?', [id])[0]);
    });
    electron_1.ipcMain.handle('notes:getCount', () => {
        const result = (0, database_1.executeQuery)('SELECT COUNT(*) as count FROM notes');
        return result[0]?.count ?? 0;
    });
    electron_1.ipcMain.handle('stickyNotes:getAll', () => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM sticky_notes ORDER BY created_at DESC');
        return rows.map(mapRowToStickyNote);
    });
    electron_1.ipcMain.handle('stickyNotes:getById', (_, id) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM sticky_notes WHERE id = ?', [id]);
        return rows.length > 0 ? mapRowToStickyNote(rows[0]) : null;
    });
    electron_1.ipcMain.handle('stickyNotes:getByColor', (_, color) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM sticky_notes WHERE color = ? ORDER BY created_at DESC', [color]);
        return rows.map(mapRowToStickyNote);
    });
    electron_1.ipcMain.handle('stickyNotes:create', (_, title, content, color, positionX, positionY) => {
        const now = Date.now();
        const id = generateStickyId();
        (0, database_1.executeInsert)(`INSERT INTO sticky_notes (id, title, content, color, position_x, position_y, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`, [id, title, content, color, positionX, positionY, now, now]);
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
    });
    electron_1.ipcMain.handle('stickyNotes:update', (_, id, updates) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM sticky_notes WHERE id = ?', [id]);
        if (rows.length === 0)
            return null;
        const existing = mapRowToStickyNote(rows[0]);
        const now = Date.now();
        (0, database_1.executeUpdate)(`UPDATE sticky_notes SET title = ?, content = ?, color = ?, position_x = ?, position_y = ?, updated_at = ?
       WHERE id = ?`, [
            updates.title ?? existing.title,
            updates.content ?? existing.content,
            updates.color ?? existing.color,
            updates.positionX ?? existing.positionX,
            updates.positionY ?? existing.positionY,
            now,
            id,
        ]);
        return mapRowToStickyNote((0, database_1.executeQuery)('SELECT * FROM sticky_notes WHERE id = ?', [id])[0]);
    });
    electron_1.ipcMain.handle('stickyNotes:updatePosition', (_, id, positionX, positionY) => {
        (0, database_1.executeUpdate)('UPDATE sticky_notes SET position_x = ?, position_y = ?, updated_at = ? WHERE id = ?', [positionX, positionY, Date.now(), id]);
        return mapRowToStickyNote((0, database_1.executeQuery)('SELECT * FROM sticky_notes WHERE id = ?', [id])[0]);
    });
    electron_1.ipcMain.handle('stickyNotes:delete', (_, id) => {
        return (0, database_1.executeUpdate)('DELETE FROM sticky_notes WHERE id = ?', [id]) > 0;
    });
    electron_1.ipcMain.handle('stickyNotes:getCount', () => {
        const result = (0, database_1.executeQuery)('SELECT COUNT(*) as count FROM sticky_notes');
        return result[0]?.count ?? 0;
    });
    electron_1.ipcMain.handle('stickyNotes:clearAll', () => {
        return (0, database_1.executeUpdate)('DELETE FROM sticky_notes');
    });
    electron_1.ipcMain.handle('categories:getAll', () => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM categories ORDER BY sort_order ASC');
        return rows.map(mapRowToCategory);
    });
    electron_1.ipcMain.handle('categories:getById', (_, id) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM categories WHERE id = ?', [id]);
        return rows.length > 0 ? mapRowToCategory(rows[0]) : null;
    });
    electron_1.ipcMain.handle('categories:create', (_, name, color) => {
        const id = generateCatId();
        const maxOrder = (0, database_1.executeQuery)('SELECT MAX(sort_order) as max_order FROM categories');
        const order = (maxOrder[0]?.max_order ?? -1) + 1;
        (0, database_1.executeInsert)('INSERT INTO categories (id, name, color, sort_order) VALUES (?, ?, ?, ?)', [id, name, color, order]);
        return { id, name, color, order };
    });
    electron_1.ipcMain.handle('categories:update', (_, id, updates) => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM categories WHERE id = ?', [id]);
        if (rows.length === 0)
            return null;
        const existing = mapRowToCategory(rows[0]);
        (0, database_1.executeUpdate)('UPDATE categories SET name = ?, color = ?, sort_order = ? WHERE id = ?', [
            updates.name ?? existing.name,
            updates.color ?? existing.color,
            updates.order ?? existing.order,
            id,
        ]);
        return mapRowToCategory((0, database_1.executeQuery)('SELECT * FROM categories WHERE id = ?', [id])[0]);
    });
    electron_1.ipcMain.handle('categories:delete', (_, id) => {
        return (0, database_1.executeUpdate)('DELETE FROM categories WHERE id = ?', [id]) > 0;
    });
    electron_1.ipcMain.handle('categories:reorder', (_, categoryIds) => {
        categoryIds.forEach((catId, index) => {
            (0, database_1.executeUpdate)('UPDATE categories SET sort_order = ? WHERE id = ?', [index, catId]);
        });
    });
    const ensureFloatingCompanionInitialized = () => {
        const count = (0, database_1.executeQuery)('SELECT COUNT(*) as cnt FROM floating_companion');
        if (count[0]?.cnt === 0) {
            (0, database_1.executeInsert)('INSERT INTO floating_companion (id, is_expanded, is_minimized, last_active_note_id, position_x, position_y) VALUES (1, 0, 0, NULL, 16, 200)');
        }
    };
    electron_1.ipcMain.handle('floatingCompanion:getState', () => {
        ensureFloatingCompanionInitialized();
        const rows = (0, database_1.executeQuery)('SELECT * FROM floating_companion WHERE id = 1');
        if (rows.length === 0) {
            return { isExpanded: false, isMinimized: false, lastActiveNoteId: null, positionX: 16, positionY: 200 };
        }
        return {
            isExpanded: rows[0].is_expanded === 1,
            isMinimized: rows[0].is_minimized === 1,
            lastActiveNoteId: rows[0].last_active_note_id,
            positionX: rows[0].position_x,
            positionY: rows[0].position_y,
        };
    });
    electron_1.ipcMain.handle('floatingCompanion:setExpanded', (_, isExpanded) => {
        ensureFloatingCompanionInitialized();
        (0, database_1.executeUpdate)('UPDATE floating_companion SET is_expanded = ? WHERE id = 1', [isExpanded ? 1 : 0]);
        return electron_1.ipcMain.invoke('floatingCompanion:getState');
    });
    electron_1.ipcMain.handle('floatingCompanion:setMinimized', (_, isMinimized) => {
        ensureFloatingCompanionInitialized();
        (0, database_1.executeUpdate)('UPDATE floating_companion SET is_minimized = ? WHERE id = 1', [isMinimized ? 1 : 0]);
        return electron_1.ipcMain.invoke('floatingCompanion:getState');
    });
    electron_1.ipcMain.handle('floatingCompanion:setPosition', (_, positionX, positionY) => {
        ensureFloatingCompanionInitialized();
        (0, database_1.executeUpdate)('UPDATE floating_companion SET position_x = ?, position_y = ? WHERE id = 1', [positionX, positionY]);
        return electron_1.ipcMain.invoke('floatingCompanion:getState');
    });
    electron_1.ipcMain.handle('floatingCompanion:setLastActiveNote', (_, noteId) => {
        ensureFloatingCompanionInitialized();
        (0, database_1.executeUpdate)('UPDATE floating_companion SET last_active_note_id = ? WHERE id = 1', [noteId]);
        return electron_1.ipcMain.invoke('floatingCompanion:getState');
    });
    electron_1.ipcMain.handle('floatingCompanion:updateState', (_, updates) => {
        ensureFloatingCompanionInitialized();
        const current = electron_1.ipcMain.invoke('floatingCompanion:getState');
        const newState = { ...current, ...updates };
        (0, database_1.executeUpdate)('UPDATE floating_companion SET is_expanded = ?, is_minimized = ?, last_active_note_id = ?, position_x = ?, position_y = ? WHERE id = 1', [newState.isExpanded ? 1 : 0, newState.isMinimized ? 1 : 0, newState.lastActiveNoteId, newState.positionX, newState.positionY]);
        return electron_1.ipcMain.invoke('floatingCompanion:getState');
    });
    electron_1.ipcMain.handle('floatingCompanion:reset', () => {
        ensureFloatingCompanionInitialized();
        (0, database_1.executeUpdate)('UPDATE floating_companion SET is_expanded = 0, is_minimized = 0, last_active_note_id = NULL, position_x = 16, position_y = 200 WHERE id = 1');
        return electron_1.ipcMain.invoke('floatingCompanion:getState');
    });
    electron_1.ipcMain.handle('settings:get', (_, key, defaultValue) => {
        const rows = (0, database_1.executeQuery)('SELECT value FROM settings WHERE key = ?', [key]);
        if (rows.length === 0)
            return defaultValue;
        try {
            return JSON.parse(rows[0].value);
        }
        catch {
            return defaultValue;
        }
    });
    electron_1.ipcMain.handle('settings:set', (_, key, value) => {
        (0, database_1.executeInsert)('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [key, JSON.stringify(value)]);
    });
    electron_1.ipcMain.handle('settings:getAll', () => {
        const rows = (0, database_1.executeQuery)('SELECT * FROM settings');
        const settings = {};
        rows.forEach(row => {
            try {
                settings[row.key] = JSON.parse(row.value);
            }
            catch {
                settings[row.key] = row.value;
            }
        });
        return settings;
    });
    electron_1.ipcMain.handle('notes:export', () => {
        const notes = (0, database_1.executeQuery)('SELECT * FROM notes ORDER BY updated_at DESC');
        const stickyNotes = (0, database_1.executeQuery)('SELECT * FROM sticky_notes ORDER BY created_at DESC');
        let content = '# NOVE Mobile Notes Export\n';
        content += `Exported on: ${new Date().toLocaleString()}\n`;
        content += '='.repeat(50) + '\n\n';
        const mappedNotes = notes.map(mapRowToNote);
        mappedNotes.forEach((note, index) => {
            content += `## ${index + 1}. ${note.title || 'Untitled'}\n`;
            content += `- Category: ${note.category || 'None'}\n`;
            content += `- Pinned: ${note.isPinned ? 'Yes' : 'No'}\n`;
            content += `- Favorite: ${note.isFavorite ? 'Yes' : 'No'}\n`;
            content += `- Created: ${new Date(note.createdAt).toLocaleString()}\n`;
            content += `- Updated: ${new Date(note.updatedAt).toLocaleString()}\n`;
            content += `- Words: ${note.wordCount}, Characters: ${note.charCount}\n\n`;
            content += note.content + '\n';
            content += '-'.repeat(50) + '\n\n';
        });
        content += '\n# Sticky Notes\n';
        content += '='.repeat(50) + '\n\n';
        stickyNotes.forEach((note, index) => {
            content += `[${note.color.toUpperCase()}] ${note.title || 'Untitled'}\n`;
            content += note.content + '\n';
            content += '-'.repeat(30) + '\n\n';
        });
        return content;
    });
};
exports.setupIpcHandlers = setupIpcHandlers;
