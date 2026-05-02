import { app, BrowserWindow, ipcMain, screen, dialog } from 'electron';
import fs from 'fs';
import path from 'path';
import { initDatabase, closeDatabase } from './database';
import { setupIpcHandlers } from './ipcHandlers';

let mainWindow: BrowserWindow | null = null;
let floatingWindow: BrowserWindow | null = null;

const createMainWindow = (): void => {
  const { width, height } = screen.getPrimaryDisplay().workAreaSize;

  mainWindow = new BrowserWindow({
    width: Math.min(1200, Math.floor(width * 0.8)),
    height: Math.min(800, Math.floor(height * 0.8)),
    minWidth: 800,
    minHeight: 600,
    title: 'NOVE',
    backgroundColor: '#FCF9F3',
    webPreferences: {
      preload: path.join(__dirname, '../preload/preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
    show: true,
  });

  mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
    console.error('Failed to load main window:', errorCode, errorDescription);
  });
};

const createFloatingWindow = (): void => {
  const { width } = screen.getPrimaryDisplay().workAreaSize;

  floatingWindow = new BrowserWindow({
    width: 280,
    height: 320,
    x: width - 300,
    y: 200,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: false,
    focusable: true,
    webPreferences: {
      preload: path.join(__dirname, '../preload/preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
    show: false,
  });

  floatingWindow.loadFile(path.join(__dirname, '../renderer/floating.html'));

  floatingWindow.on('closed', () => {
    floatingWindow = null;
  });

  floatingWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
    console.error('Failed to load floating window:', errorCode, errorDescription);
  });
};

app.whenReady().then(() => {
  try {
    console.log('Initializing database...');
    initDatabase();
    console.log('Setting up IPC handlers...');
    setupIpcHandlers();
    console.log('Creating main window...');
    createMainWindow();
    console.log('Creating floating window...');
    createFloatingWindow();
    console.log('NOVE Desktop started successfully');
  } catch (err) {
    console.error('Failed to start NOVE:', err);
  }
});

ipcMain.handle('window:toggleFloating', () => {
  if (floatingWindow) {
    if (floatingWindow.isVisible()) {
      floatingWindow.hide();
    } else {
      floatingWindow.show();
    }
  }
});

ipcMain.handle('window:showFloating', () => {
  floatingWindow?.show();
});

ipcMain.handle('window:hideFloating', () => {
  floatingWindow?.hide();
});

ipcMain.handle('dialog:saveFile', async (_, content: string, defaultName: string) => {
  const result = await dialog.showSaveDialog(mainWindow!, {
    defaultPath: defaultName,
    filters: [{ name: 'Text Files', extensions: ['txt'] }],
  });
  
  if (!result.canceled && result.filePath) {
    fs.writeFileSync(result.filePath, content, 'utf8');
    return true;
  }
  return false;
});

ipcMain.handle('app:getTheme', () => {
  return 'light';
});

ipcMain.handle('app:setTheme', (_, theme: string) => {
  return theme;
});

app.on('window-all-closed', () => {
  closeDatabase();
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createMainWindow();
  }
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught exception:', error);
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled rejection:', reason);
});
