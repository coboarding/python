// Funkcja konfiguracji rozpoznawania głosu
export function setupVoiceRecognition(socket) {
  const startButton = document.getElementById('start-voice');
  const voiceStatus = document.getElementById('voice-status');
  const transcript = document.getElementById('transcript');

  // Sprawdzenie czy przeglądarka wspiera rozpoznawanie mowy
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

  if (!SpeechRecognition) {
    voiceStatus.textContent = 'Speech recognition not supported in this browser';
    startButton.disabled = true;
    return;
  }

  // Inicjalizacja rozpoznawania mowy
  const recognition = new SpeechRecognition();
  recognition.continuous = false;
  recognition.interimResults = true;
  recognition.lang = 'pl-PL';

  let isListening = false;

  // Przełączanie nasłuchiwania
  startButton.addEventListener('click', () => {
    if (isListening) {
      recognition.stop();
      startButton.textContent = 'Start Voice Recognition';
      voiceStatus.textContent = 'Ready';
      isListening = false;
    } else {
      recognition.start();
      startButton.textContent = 'Stop Voice Recognition';
      voiceStatus.textContent = 'Listening...';
      isListening = true;
    }
  });

  // Obsługa wyniku rozpoznawania
  recognition.onresult = (event) => {
    const last = event.results.length - 1;
    const result = event.results[last][0].transcript;

    // Aktualizacja UI
    transcript.textContent = result;

    // Sprawdzenie czy to finalne rozpoznanie
    if (event.results[last].isFinal) {
      processCommand(result);
    }
  };

  // Obsługa błędów
  recognition.onerror = (event) => {
    voiceStatus.textContent = `Error: ${event.error}`;
    isListening = false;
    startButton.textContent = 'Start Voice Recognition';
  };

  // Automatyczne wznowienie nasłuchiwania po zakończeniu
  recognition.onend = () => {
    if (isListening) {
      setTimeout(() => {
        recognition.start();
      }, 500);
    }
  };

  // Przetwarzanie rozpoznanej komendy
  function processCommand(text) {
    // Mapowanie komend głosowych na akcje
    const commandPatterns = [
      { regex: /wypełnij (formularz|formularze)? ?(.+)?/i, action: 'fill_form', extractParam: (match) => match[2] },
      { regex: /(uruchom|rozpocznij) (test|testy)/i, action: 'run_test' },
      { regex: /pokaż (status|stan)/i, action: 'show_status' },
      { regex: /(pokaż|lista) (formularz|formularze)/i, action: 'list_forms' },
      { regex: /(wybierz|ustaw) model/i, action: 'select_model' },
      { regex: /pomoc/i, action: 'help' },
      { regex: /generuj pipeline/i, action: 'generate_pipeline' }
    ];

    for (const pattern of commandPatterns) {
      const match = text.match(pattern.regex);
      if (match) {
        let params = {};
        if (pattern.extractParam && match[2]) {
          if (pattern.action === 'fill_form') {
            params.url = match[2];
          }
        }

        // Wysłanie komendy do serwera
        socket.emit('voice_command', {
          command: pattern.action,
          params: params
        });

        voiceStatus.textContent = `Executing: ${pattern.action}`;
        return;
      }
    }

    // Jeśli nie rozpoznano komendy
    voiceStatus.textContent = 'Command not recognized';
  }

  // Obsługa odpowiedzi głosowej
  socket.on('voice_response', (data) => {
    if (data.audioUrl) {
      playAudio(data.audioUrl);
    }

    if (data.text) {
      voiceStatus.textContent = `Response: ${data.text}`;
    }
  });

  // Odtwarzanie odpowiedzi audio
  function playAudio(url) {
    const audio = new Audio(url);
    audio.play();
  }
}