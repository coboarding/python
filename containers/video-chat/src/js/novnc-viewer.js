// Funkcja konfiguracji podglądu noVNC
export function setupNoVNCViewer() {
  const novncContainer = document.getElementById('novnc-viewer');

  // Tworzenie iframe z podglądem noVNC
  const iframe = document.createElement('iframe');
  iframe.src = process.env.NOVNC_URL || 'http://localhost:8080';
  iframe.className = 'novnc-iframe';
  iframe.title = 'NoVNC Viewer';
  iframe.allowFullscreen = true;

  // Czyszczenie kontenera i dodanie iframe
  novncContainer.innerHTML = '';
  novncContainer.appendChild(iframe);

  // Obsługa komunikacji między iframe a głównym oknem
  window.addEventListener('message', (event) => {
    // Tu można dodać obsługę komunikatów z iframe noVNC
    if (event.data && event.data.type === 'novnc_event') {
      console.log('NoVNC event:', event.data);
    }
  });
}