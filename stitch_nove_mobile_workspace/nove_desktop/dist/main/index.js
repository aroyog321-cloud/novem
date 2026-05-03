"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const electron_1 = require("electron");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const database_1 = require("./database");
const ipcHandlers_1 = require("./ipcHandlers");
let mainWindow = null;
let floatingWindow = null;
const createMainWindow = () => {
    const { width, height } = electron_1.screen.getPrimaryDisplay().workAreaSize;
    mainWindow = new electron_1.BrowserWindow({
        width: Math.min(1200, Math.floor(width * 0.8)),
        height: Math.min(800, Math.floor(height * 0.8)),
        minWidth: 800,
        minHeight: 600,
        title: 'NOVE',
        backgroundColor: '#FCF9F3',
        webPreferences: {
            preload: path_1.default.join(__dirname, '../preload/preload.js'),
            contextIsolation: true,
            nodeIntegration: false,
        },
        show: true,
    });
    mainWindow.loadFile(path_1.default.join(__dirname, '../renderer/index.html'));
    mainWindow.on('closed', () => {
        mainWindow = null;
    });
    mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
        console.error('Failed to load main window:', errorCode, errorDescription);
    });
};
const createFloatingWindow = () => {
    const { width } = electron_1.screen.getPrimaryDisplay().workAreaSize;
    floatingWindow = new electron_1.BrowserWindow({
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
            preload: path_1.default.join(__dirname, '../preload/preload.js'),
            contextIsolation: true,
            nodeIntegration: false,
        },
        show: false,
    });
    floatingWindow.loadFile(path_1.default.join(__dirname, '../renderer/floating.html'));
    floatingWindow.on('closed', () => {
        floatingWindow = null;
    });
    floatingWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
        console.error('Failed to load floating window:', errorCode, errorDescription);
    });
};
electron_1.app.whenReady().then(() => {
    try {
        console.log('Initializing database...');
        (0, database_1.initDatabase)();
        console.log('Setting up IPC handlers...');
        (0, ipcHandlers_1.setupIpcHandlers)();
        console.log('Creating main window...');
        createMainWindow();
        console.log('Creating floating window...');
        createFloatingWindow();
        console.log('NOVE Desktop started successfully');
    }
    catch (err) {
        console.error('Failed to start NOVE:', err);
    }
});
electron_1.ipcMain.handle('window:toggleFloating', () => {
    if (floatingWindow) {
        if (floatingWindow.isVisible()) {
            floatingWindow.hide();
        }
        else {
            floatingWindow.show();
        }
    }
});
electron_1.ipcMain.handle('window:showFloating', () => {
    floatingWindow?.show();
});
electron_1.ipcMain.handle('window:hideFloating', () => {
    floatingWindow?.hide();
});
electron_1.ipcMain.handle('dialog:saveFile', async (_, content, defaultName) => {
    const result = await electron_1.dialog.showSaveDialog(mainWindow, {
        defaultPath: defaultName,
        filters: [{ name: 'Text Files', extensions: ['txt'] }],
    });
    if (!result.canceled && result.filePath) {
        fs_1.default.writeFileSync(result.filePath, content, 'utf8');
        return true;
    }
    return false;
});
electron_1.ipcMain.handle('app:getTheme', () => {
    return 'light';
});
electron_1.ipcMain.handle('app:setTheme', (_, theme) => {
    return theme;
});
electron_1.app.on('window-all-closed', () => {
    (0, database_1.closeDatabase)();
    if (process.platform !== 'darwin') {
        electron_1.app.quit();
    }
});
electron_1.app.on('activate', () => {
    if (electron_1.BrowserWindow.getAllWindows().length === 0) {
        createMainWindow();
    }
});
process.on('uncaughtException', (error) => {
    console.error('Uncaught exception:', error);
});
process.on('unhandledRejection', (reason) => {
    console.error('Unhandled rejection:', reason);
});
