const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  notes: {
    getAll: () => ipcRenderer.invoke('notes:getAll'),
    getById: (id) => ipcRenderer.invoke('notes:getById', id),
    getByCategory: (category) => ipcRenderer.invoke('notes:getByCategory', category),
    getPinned: () => ipcRenderer.invoke('notes:getPinned'),
    getFavorites: () => ipcRenderer.invoke('notes:getFavorites'),
    search: (query) => ipcRenderer.invoke('notes:search', query),
    create: (content, category, colorLabel) => ipcRenderer.invoke('notes:create', content, category, colorLabel),
    update: (id, updates) => ipcRenderer.invoke('notes:update', id, updates),
    delete: (id) => ipcRenderer.invoke('notes:delete', id),
    togglePin: (id) => ipcRenderer.invoke('notes:togglePin', id),
    toggleFavorite: (id) => ipcRenderer.invoke('notes:toggleFavorite', id),
    getCount: () => ipcRenderer.invoke('notes:getCount'),
    export: () => ipcRenderer.invoke('notes:export'),
  },
  stickyNotes: {
    getAll: () => ipcRenderer.invoke('stickyNotes:getAll'),
    getById: (id) => ipcRenderer.invoke('stickyNotes:getById', id),
    getByColor: (color) => ipcRenderer.invoke('stickyNotes:getByColor', color),
    create: (title, content, color, x, y) => ipcRenderer.invoke('stickyNotes:create', title, content, color, x, y),
    update: (id, updates) => ipcRenderer.invoke('stickyNotes:update', id, updates),
    updatePosition: (id, x, y) => ipcRenderer.invoke('stickyNotes:updatePosition', id, x, y),
    delete: (id) => ipcRenderer.invoke('stickyNotes:delete', id),
    getCount: () => ipcRenderer.invoke('stickyNotes:getCount'),
    clearAll: () => ipcRenderer.invoke('stickyNotes:clearAll'),
  },
  categories: {
    getAll: () => ipcRenderer.invoke('categories:getAll'),
    getById: (id) => ipcRenderer.invoke('categories:getById', id),
    create: (name, color) => ipcRenderer.invoke('categories:create', name, color),
    update: (id, updates) => ipcRenderer.invoke('categories:update', id, updates),
    delete: (id) => ipcRenderer.invoke('categories:delete', id),
    reorder: (ids) => ipcRenderer.invoke('categories:reorder', ids),
  },
  floatingCompanion: {
    getState: () => ipcRenderer.invoke('floatingCompanion:getState'),
    setExpanded: (isExpanded) => ipcRenderer.invoke('floatingCompanion:setExpanded', isExpanded),
    setMinimized: (isMinimized) => ipcRenderer.invoke('floatingCompanion:setMinimized', isMinimized),
    setPosition: (x, y) => ipcRenderer.invoke('floatingCompanion:setPosition', x, y),
    setLastActiveNote: (noteId) => ipcRenderer.invoke('floatingCompanion:setLastActiveNote', noteId),
    updateState: (updates) => ipcRenderer.invoke('floatingCompanion:updateState', updates),
    reset: () => ipcRenderer.invoke('floatingCompanion:reset'),
  },
  settings: {
    get: (key, defaultValue) => ipcRenderer.invoke('settings:get', key, defaultValue),
    set: (key, value) => ipcRenderer.invoke('settings:set', key, value),
    getAll: () => ipcRenderer.invoke('settings:getAll'),
  },
  window: {
    toggleFloating: () => ipcRenderer.invoke('window:toggleFloating'),
    showFloating: () => ipcRenderer.invoke('window:showFloating'),
    hideFloating: () => ipcRenderer.invoke('window:hideFloating'),
  },
  dialog: {
    saveFile: (content, name) => ipcRenderer.invoke('dialog:saveFile', content, name),
  },
  app: {
    getTheme: () => ipcRenderer.invoke('app:getTheme'),
    setTheme: (theme) => ipcRenderer.invoke('app:setTheme', theme),
  },
});
