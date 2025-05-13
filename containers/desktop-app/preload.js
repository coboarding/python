const { contextBridge, ipcRenderer } = require('electron');

// Eksponowanie API dla kodu renderującego
contextBridge.exposeInMainWorld('autoFormFiller', {
  getAppVersion: () => process.env.npm_package_version,
  requestContainersStatus: () => ipcRenderer.invoke('check-containers'),
  restartContainers: () => ipcRenderer.invoke('restart-containers')
});

// Nasłuchiwanie na komunikaty
window.addEventListener('DOMContentLoaded', () => {
  // Przekierowanie console.log do loggera Electron
  const originalConsoleLog = console.log;
  console.log = (...args) => {
    ipcRenderer.send('log', { type: 'log', args });
    originalConsoleLog(...args);
  };

  const originalConsoleError = console.error;
  console.error = (...args) => {
    ipcRenderer.send('log', { type: 'error', args });
    originalConsoleError(...args);
  };
});