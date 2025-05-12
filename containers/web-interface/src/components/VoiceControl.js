// web-interface/src/App.js (fragment)
import VoiceControl from './components/VoiceControl';

// Wewnątrz komponentu App
const handleVoiceCommand = (action, params) => {
  switch(action) {
    case 'fill_form':
      if (params.url) {
        setUrl(params.url);
        // Opcjonalnie: automatyczne rozpoczęcie wypełniania
        setTimeout(() => handleFillForm(), 500);
      } else {
        // Jeśli URL nie został podany w komendzie głosowej, ale jest już ustawiony
        if (url) {
          handleFillForm();
        } else {
          setMessage('Proszę podać URL formularza lub powiedzieć "wypełnij formularz [adres URL]"');
        }
      }
      break;

    case 'run_test':
      // Uruchom testy
      fetch('/api/run-tests', { method: 'POST' })
        .then(res => res.json())
        .then(data => {
          setMessage(`Testy uruchomione. Status: ${data.status}`);
        });
      break;

    case 'show_status':
      // Pobierz i pokaż status systemu
      fetch('/api/status')
        .then(res => res.json())
        .then(data => {
          setMessage(`Status systemu: ${data.status}. Aktywny model: ${data.active_model}`);
        });
      break;

    case 'list_forms':
      // Pokaż historię wypełnionych formularzy
      fetch('/api/history')
        .then(res => res.json())
        .then(data => {
          setHistory(data.history);
          setMessage('Wyświetlam listę formularzy');
        });
      break;

    case 'select_model':
      // Pokaż dialog wyboru modelu
      setShowModelSelector(true);
      setMessage('Proszę wybrać model LLM');
      break;

    case 'help':
      setMessage('Dostępne komendy: "wypełnij formularz [URL]", "uruchom test", "pokaż status", "lista formularzy", "wybierz model"');
      break;

    default:
      setMessage('Nieznana komenda');
  }
};

// W renderze komponentu
return (
  <div className="App">
    {/* Istniejący kod */}

    <section className="voice-section">
      <h2>Sterowanie głosowe</h2>
      <VoiceControl onCommand={handleVoiceCommand} />
    </section>

    {/* Reszta istniejącego kodu */}
  </div>
);