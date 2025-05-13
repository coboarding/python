const { app, BrowserWindow, Menu, Tray, dialog, ipcMain } = require('electron');
const path = require('path');
const url = require('url');
const { spawn, exec } = require('child_process');
const fs = require('fs');
const axios = require('axios');
const log = require('electron-log');
const { autoUpdater } = require('electron-updater');
const Dockerode = require('dockerode');

// Konfiguracja logowania
log.transports.file.level = 'info';
log.info('Uruchamianie aplikacji coboarding...');

// Globalne zmienne
let mainWindow;
let tray;
let dockerComposeProcess;
let isDockerRunning = false;
let startupWindow;

// Ścieżki do zasobów
const dockerComposePath = process.env.NODE_ENV === 'development'
  ? path.join(__dirname, '..', '..') // Ścieżka deweloperska
  : path.join(process.resourcesPath, 'docker-compose'); // Ścieżka produkcyjna

// Sprawdzenie dostępności Dockera
function checkDockerAvailability() {
  return new Promise((resolve, reject) => {
    exec('docker --version', (error) => {
      if (error) {
        log.error('Docker nie jest zainstalowany lub niedostępny:', error);
        resolve(false);
      } else {
        log.info('Docker jest dostępny');
        resolve(true);
      }
    });
  });
}

// Uruchomienie kontenerów przez Docker Compose
function startContainers() {
  return new Promise((resolve, reject) => {
    log.info('Uruchamianie kontenerów Docker...');
    showStartupScreen('Uruchamianie kontenerów Docker...');

    // Sprawdź, czy katalogi wolumenów istnieją
    const volumePaths = ['cv', 'models', 'config', 'passwords', 'recordings', 'pipelines'];
    volumePaths.forEach(dir => {
      const dirPath = path.join(dockerComposePath, 'volumes', dir);
      if (!fs.existsSync(dirPath)) {
        log.info(`Tworzenie katalogu ${dirPath}`);
        fs.mkdirSync(dirPath, { recursive: true });
      }
    });

    dockerComposeProcess = spawn('docker-compose', ['up', '-d'], {
      cwd: dockerComposePath,
      shell: true
    });

    dockerComposeProcess.stdout.on('data', (data) => {
      log.info(`Docker Compose stdout: ${data}`);
      showStartupScreen(`Uruchamianie kontenerów: ${data}`);
    });

    dockerComposeProcess.stderr.on('data', (data) => {
      log.error(`Docker Compose stderr: ${data}`);
      showStartupScreen(`Błąd: ${data}`, true);
    });

    dockerComposeProcess.on('close', (code) => {
      if (code === 0) {
        log.info('Kontenery Docker uruchomione pomyślnie');
        isDockerRunning = true;
        resolve();
      } else {
        log.error(`Docker Compose zakończył działanie z kodem: ${code}`);
        reject(new Error(`Docker Compose zakończył działanie z kodem: ${code}`));
      }
    });
  });
}

// Zatrzymanie kontenerów
function stopContainers() {
  return new Promise((resolve, reject) => {
    if (!isDockerRunning) {
      resolve();
      return;
    }

    log.info('Zatrzymywanie kontenerów Docker...');

    exec('docker-compose down', { cwd: dockerComposePath }, (error, stdout, stderr) => {
      if (error) {
        log.error(`Błąd podczas zatrzymywania kontenerów: ${error.message}`);
        reject(error);
        return;
      }

      log.info(`Docker Compose down stdout: ${stdout}`);
      if (stderr) log.error(`Docker Compose down stderr: ${stderr}`);

      isDockerRunning = false;
      resolve();
    });
  });
}

// Sprawdzenie statusu kontenerów
function checkContainersStatus() {
  return new Promise((resolve, reject) => {
    exec('docker-compose ps', { cwd: dockerComposePath }, (error, stdout, stderr) => {
      if (error) {
        log.error(`Błąd podczas sprawdzania statusu kontenerów: ${error.message}`);
        reject(error);
        return;
      }

      const containersRunning = stdout.includes('Up') && !stdout.includes('Exit');
      isDockerRunning = containersRunning;

      log.info(`Status kontenerów - uruchomione: ${containersRunning}`);
      resolve(containersRunning);
    });
  });
}

// Okno startowe podczas uruchamiania
function showStartupScreen(message, isError = false) {
  if (!startupWindow) {
    startupWindow = new BrowserWindow({
      width: 400,
      height: 300,
      frame: false,
      resizable: false,
      transparent: true,
      webPreferences: {
        nodeIntegration: true,
        contextIsolation: false
      }
    });

    startupWindow.loadURL(url.format({
      pathname: path.join(__dirname, 'startup.html'),
      protocol: 'file:',
      slashes: true
    }));

    startupWindow.on('closed', () => {
      startupWindow = null;
    });
  }

  if (startupWindow) {
    startupWindow.webContents.send('update-message', { message, isError });
  }
}

// Tworzenie głównego okna aplikacji
function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: path.join(__dirname, 'assets', 'icons', 'png', 'icon.png')
  });

  // Ustawienie menu
  const template = [
    {
      label: 'Aplikacja',
      submenu: [
        {
          label: 'Sprawdź statusy kontenerów',
          click: async () => {
            const isRunning = await checkContainersStatus();
            dialog.showMessageBox(mainWindow, {
              type: isRunning ? 'info' : 'warning',
              title: 'Status kontenerów',
              message: isRunning ? 'Wszystkie kontenery działają poprawnie.' : 'Niektóre kontenery nie są uruchomione.'
            });
          }
        },
        {
          label: 'Restart kontenerów',
          click: async () => {
            await stopContainers();
            await startContainers();
            dialog.showMessageBox(mainWindow, {
              type: 'info',
              title: 'Restart kontenerów',
              message: 'Kontenery zostały zrestartowane.'
            });
          }
        },
        { type: 'separator' },
        {
          label: 'Zamknij',
          click: () => {
            app.quit();
          }
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);

  // Po uruchomieniu kontenerów, otwórz interfejs webowy
  mainWindow.loadURL('http://localhost:8082');

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// Tworzenie ikony w zasobniku
function createTray() {
  tray = new Tray(path.join(__dirname, 'assets', 'icons', 'png', '16x16.png'));

  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Pokaż okno główne',
      click: () => {
        if (mainWindow === null) {
          createMainWindow();
        } else {
          mainWindow.show();
        }
      }
    },
    {
      label: 'Status kontenerów',
      click: async () => {
        const isRunning = await checkContainersStatus();
        dialog.showMessageBox({
          type: isRunning ? 'info' : 'warning',
          title: 'Status kontenerów',
          message: isRunning ? 'Wszystkie kontenery działają poprawnie.' : 'Niektóre kontenery nie są uruchomione.'
        });
      }
    },
    { type: 'separator' },
    {
      label: 'Restart systemu',
      click: async () => {
        await stopContainers();
        await startContainers();
        dialog.showMessageBox({
          type: 'info',
          title: 'Restart systemu',
          message: 'System został zrestartowany.'
        });
      }
    },
    { type: 'separator' },
    {
      label: 'Zamknij',
      click: () => {
        app.quit();
      }
    }
  ]);

  tray.setToolTip('coboarding');
  tray.setContextMenu(contextMenu);

  tray.on('click', () => {
    if (mainWindow === null) {
      createMainWindow();
    } else {
      mainWindow.show();
    }
  });
}

// Inicjalizacja aplikacji
app.on('ready', async () => {
  log.info('Aplikacja gotowa do uruchomienia');

  // Sprawdzenie auto-aktualizacji
  autoUpdater.checkForUpdatesAndNotify();

  // Tworzenie tray
  createTray();

  // Pokaż ekran startowy
  showStartupScreen('Sprawdzanie środowiska Docker...');

  try {
    // Sprawdź dostępność Dockera
    const isDockerAvailable = await checkDockerAvailability();

    if (!isDockerAvailable) {
      showStartupScreen('Docker nie jest zainstalowany lub niedostępny. Zainstaluj Docker, aby kontynuować.', true);
      dialog.showErrorBox(
        'Docker nie jest dostępny',
        'coboarding wymaga zainstalowanego i uruchomionego Dockera. Zainstaluj Docker i uruchom aplikację ponownie.'
      );

      if (startupWindow) {
        startupWindow.close();
        startupWindow = null;
      }

      return;
    }

    // Sprawdź status kontenerów
    const containersRunning = await checkContainersStatus();

    if (!containersRunning) {
      // Uruchom kontenery
      await startContainers();
    }

    // Zamknij ekran startowy
    if (startupWindow) {
      startupWindow.close();
      startupWindow = null;
    }

    // Otwórz główne okno
    createMainWindow();

  } catch (error) {
    log.error('Błąd podczas inicjalizacji:', error);

    showStartupScreen(`Wystąpił błąd: ${error.message}`, true);
    dialog.showErrorBox(
      'Błąd inicjalizacji',
      `Wystąpił błąd podczas uruchamiania systemu: ${error.message}`
    );

    if (startupWindow) {
      setTimeout(() => {
        startupWindow.close();
        startupWindow = null;
      }, 5000);
    }
  }
});

// Zapobiegaj tworzeniu wielu instancji aplikacji
const gotSingleInstanceLock = app.requestSingleInstanceLock();
if (!gotSingleInstanceLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });
}

// Zamknięcie aplikacji
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createMainWindow();
  }
});

// Zatrzymaj kontenery przed zamknięciem
app.on('before-quit', async (event) => {
  if (isDockerRunning) {
    event.preventDefault();
    await stopContainers();
    app.quit();
  }
});

// Obsługa auto-aktualizacji
autoUpdater.on('update-available', () => {
  dialog.showMessageBox({
    type: 'info',
    title: 'Dostępna aktualizacja',
    message: 'Dostępna jest nowa wersja aplikacji. Aktualizacja zostanie pobrana automatycznie.'
  });
});

autoUpdater.on('update-downloaded', () => {
  dialog.showMessageBox({
    type: 'info',
    title: 'Aktualizacja gotowa',
    message: 'Aktualizacja została pobrana. Aplikacja zostanie uruchomiona ponownie, aby zainstalować aktualizację.'
  }).then(() => {
    autoUpdater.quitAndInstall();
  });
});