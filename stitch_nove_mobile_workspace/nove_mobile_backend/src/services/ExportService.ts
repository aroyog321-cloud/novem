import RNFS from 'react-native-fs';
import { NoteService } from './NoteService';
import { StickyNoteService } from './StickyNoteService';
import { CategoryService } from './CategoryService';
import { ExportData } from '../types';

const EXPORT_VERSION = 1;

export class ExportService {
  static async exportAllData(): Promise<string> {
    const notes = NoteService.getAllNotes();
    const stickyNotes = StickyNoteService.getAllStickyNotes();
    const categories = CategoryService.getAllCategories();

    const exportData: ExportData = {
      version: EXPORT_VERSION,
      exportedAt: Date.now(),
      notes,
      stickyNotes,
      categories,
    };

    const fileName = `nove_backup_${Date.now()}.json`;
    const filePath = `${RNFS.DocumentDirectoryPath}/${fileName}`;

    await RNFS.writeFile(filePath, JSON.stringify(exportData, null, 2), 'utf8');

    return filePath;
  }

  static async exportNotesAsTxt(): Promise<string> {
    const notes = NoteService.getAllNotes();
    
    let content = '# NOVE Mobile Notes Export\n';
    content += `Exported on: ${new Date().toLocaleString()}\n`;
    content += '='.repeat(50) + '\n\n';

    notes.forEach((note, index) => {
      content += `## ${index + 1}. ${note.title || 'Untitled'}\n`;
      content += `- Category: ${note.category || 'None'}\n`;
      content += `- Created: ${new Date(note.createdAt).toLocaleString()}\n`;
      content += `- Updated: ${new Date(note.updatedAt).toLocaleString()}\n`;
      content += `- Words: ${note.wordCount}, Characters: ${note.charCount}\n\n`;
      content += note.content + '\n';
      content += '-'.repeat(50) + '\n\n';
    });

    const fileName = `nove_notes_${Date.now()}.txt`;
    const filePath = `${RNFS.DocumentDirectoryPath}/${fileName}`;

    await RNFS.writeFile(filePath, content, 'utf8');

    return filePath;
  }

  static async exportStickyNotesAsTxt(): Promise<string> {
    const stickyNotes = StickyNoteService.getAllStickyNotes();

    let content = '# NOVE Mobile Sticky Notes Export\n';
    content += `Exported on: ${new Date().toLocaleString()}\n`;
    content += '='.repeat(50) + '\n\n';

    const colorEmoji: Record<string, string> = {
      yellow: '🟡',
      pink: '🔴',
      green: '🟢',
      blue: '🔵',
    };

    stickyNotes.forEach((note, index) => {
      const emoji = colorEmoji[note.color] || '📝';
      content += `${emoji} ${note.title || 'Untitled'}\n`;
      content += note.content + '\n';
      content += '-'.repeat(30) + '\n\n';
    });

    const fileName = `nove_sticky_notes_${Date.now()}.txt`;
    const filePath = `${RNFS.DocumentDirectoryPath}/${fileName}`;

    await RNFS.writeFile(filePath, content, 'utf8');

    return filePath;
  }

  static formatNoteForShare(note: { title: string; content: string }): string {
    return `${note.title || 'Untitled'}\n\n${note.content}`;
  }

  static formatStickyNoteForShare(note: { title: string; content: string; color: string }): string {
    return `[${note.color.toUpperCase()} NOTE]\n${note.title || 'Untitled'}\n\n${note.content}`;
  }
}
