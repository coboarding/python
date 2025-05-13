import io from 'socket.io-client';
import { setupVoiceRecognition } from './voice-recognition';
import { setupPipelineViewer } from './pipeline-viewer';
import { setupNoVNCViewer } from './novnc-viewer';

// Inicjalizacja głównej aplikacji
export function initApp() {
  const appContainer = document.getElementById('app');

  // Tworzenie struktury interfejsu
  appContainer.innerHTML = `
    <div class="video-chat-container">
      <header class="video-chat-header">
        <h1>AutoFormFiller Video Chat</h1>
        <div class="status-indicator">
          <span class="status-dot"></span>
          <span class="status-text">Ready</span>
        </div>
      </header>
      
      <main class="video-chat-main">
        <section class="novnc-container" id="novnc-viewer">
          <div class="novnc-loading">Loading NoVNC viewer...</div>
        </section>
        
        <section class="sidebar">
          <div class="voice-control-panel" id="voice-control">
            <h2>Voice Control</h2>
            <button id="start-voice" class="primary-button">Start Voice Recognition</button>
            <div id="voice-status" class="voice-status">Ready</div>
            <div id="transcript" class="transcript"></div>
          </div>
          
          <div class="pipeline-viewer" id="pipeline-viewer">
            <h2>Pipeline Viewer</h2>
            <div class="pipeline-content" id="pipeline-content">
              <p>No active pipeline</p>
            </div>
          </div>
        </section>
      </main>
      
      <footer class="video-chat-footer">
        <p>AutoFormFiller &copy; 2025</p>
      </footer>
    </div>
  `;

  // Ustanowienie połączenia WebSocket
  const socket = io(window.location.origin, {
    path: '/socket.io',
    transports: ['websocket']
  });

  // Obsługa zdarzeń połączenia
  socket.on('connect', () => {
    updateStatus('Connected', true);
    console.log('Connected to server with ID:', socket.id);

    // Subskrypcja aktualizacji pipeline'ów
    socket.emit('subscribe_pipelines');
  });

  socket.on('disconnect', () => {
    updateStatus('Disconnected', false);
    console.log('Disconnected from server');
  });

  socket.on('error', (data) => {
    console.error('Socket error:', data.message);
    updateStatus('Error: ' + data.message, false);
  });

  // Inicjalizacja komponentów
  setupVoiceRecognition(socket);
  setupPipelineViewer(socket);
  setupNoVNCViewer();

  // Funkcja aktualizacji statusu
  function updateStatus(text, isConnected) {
    const statusDot = document.querySelector('.status-dot');
    const statusText = document.querySelector('.status-text');

    statusText.textContent = text;

    if (isConnected) {
      statusDot.classList.add('connected');
      statusDot.classList.remove('disconnected');
    } else {
      statusDot.classList.add('disconnected');
      statusDot.classList.remove('connected');
    }
  }
}