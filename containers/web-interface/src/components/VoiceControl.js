import React, { useState, useEffect, useRef } from 'react';
import './VoiceControl.css';

const VoiceControl = ({ onCommand }) => {
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [error, setError] = useState('');
  const [supportsSpeech, setSupportsSpeech] = useState(false);

  const recognitionRef = useRef(null);

  useEffect(() => {
    // Sprawdź wsparcie dla API rozpoznawania mowy
    if ('SpeechRecognition' in window || 'webkitSpeechRecognition' in window) {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      recognitionRef.current = new SpeechRecognition();
      recognitionRef.current.continuous = false;
      recognitionRef.current.interimResults = false;
      recognitionRef.current.lang = 'pl-PL';

      recognitionRef.current.onresult = (event) => {
        const lastResultIndex = event.results.length - 1;
        const detectedText = event.results[lastResultIndex][0].transcript;
        setTranscript(detectedText);

        // Przekaż komendę do przetworzenia
        processCommand(detectedText);
      };

      recognitionRef.current.onerror = (event) => {
        setError(`Błąd rozpoznawania: ${event.error}`);
        setIsListening(false);
      };

      recognitionRef.current.onend = () => {
        setIsListening(false);
      };

      setSupportsSpeech(true);
    } else {
      setSupportsSpeech(false);
      setError('Twoja przeglądarka nie obsługuje rozpoznawania mowy.');
    }

    return () => {
      if (recognitionRef.current) {
        recognitionRef.current.abort();
      }
    };
  }, []);

  const toggleListening = () => {
    if (isListening) {
      recognitionRef.current.stop();
      setIsListening(false);
    } else {
      setError('');
      setTranscript('');
      recognitionRef.current.start();
      setIsListening(true);
    }
  };

  const processCommand = (text) => {
    // Mapowanie komend głosowych na akcje
    const commandPatterns = [
      { regex: /wypełnij (formularz|formularze)? ?(.+)?/i, action: 'fill_form', extractParam: (match) => match[2] },
      { regex: /(uruchom|rozpocznij) (test|testy)/i, action: 'run_test' },
      { regex: /pokaż (status|stan)/i, action: 'show_status' },
      { regex: /(pokaż|lista) (formularz|formularze)/i, action: 'list_forms' },
      { regex: /(wybierz|ustaw) model/i, action: 'select_model' },
      { regex: /pomoc/i, action: 'help' }
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

        // Wykonaj komendę lokalnie
        onCommand(pattern.action, params);

        // Dodatkowe wykonanie komendy przez API
        fetch('/api/voice/execute-command', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            command: pattern.action,
            params: params
          }),
        })
        .then(response => response.json())
        .then(data => {
          if (data.success && data.result && data.result.message) {
            speak(data.result.message);
          }
        })
        .catch(error => {
          console.error('Error executing command:', error);
        });

        return;
      }
    }

    // Nie rozpoznano komendy
    speak('Nie rozpoznałem komendy. Powiedz "pomoc" aby usłyszeć dostępne komendy.');
  };

  // Funkcja do syntezy mowy
  const speak = (text) => {
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'pl-PL';
      window.speechSynthesis.speak(utterance);
    }
  };

  if (!supportsSpeech) {
    return (
      <div className="voice-control error">
        <p>{error || 'Rozpoznawanie mowy nie jest obsługiwane przez tę przeglądarkę.'}</p>
      </div>
    );
  }

  return (
    <div className="voice-control">
      <button
        className={`voice-button ${isListening ? 'listening' : ''}`}
        onClick={toggleListening}
      >
        {isListening ? 'Słucham...' : 'Sterowanie głosowe'}
      </button>

      {isListening && (
        <div className="listening-indicator">
          <div className="pulse"></div>
          <p>Powiedz komendę...</p>
        </div>
      )}

      {transcript && (
        <div className="transcript">
          <p>Rozpoznano: <strong>{transcript}</strong></p>
        </div>
      )}

      {error && (
        <div className="error">
          <p>{error}</p>
        </div>
      )}
    </div>
  );
};

export default VoiceControl;