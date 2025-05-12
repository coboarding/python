// web-interface/src/App.js
import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [cvFiles, setCvFiles] = useState([]);
  const [selectedCv, setSelectedCv] = useState('');
  const [url, setUrl] = useState('');
  const [status, setStatus] = useState('idle');
  const [message, setMessage] = useState('');
  const [history, setHistory] = useState([]);
  const [models, setModels] = useState([]);
  const [selectedModel, setSelectedModel] = useState('');
  const [recording, setRecording] = useState(false);

  useEffect(() => {
    // Pobierz dostępne CV
    fetch('/api/cv-files')
      .then(res => res.json())
      .then(data => {
        setCvFiles(data.files);
        if (data.files.length > 0) {
          setSelectedCv(data.files[0]);
        }
      });
    
    // Pobierz dostępne modele
    fetch('/api/models')
      .then(res => res.json())
      .then(data => {
        setModels(data.models);
        if (data.models.length > 0) {
          setSelectedModel(data.models[0].id);
        }
      });
    
    // Pobierz historię
    fetch('/api/history')
      .then(res => res.json())
      .then(data => {
        setHistory(data.history);
      });
  }, []);

  const handleFillForm = async () => {
    if (!url) {
      setMessage('Proszę podać URL formularza');
      return;
    }
    
    setStatus('loading');
    setMessage('Wypełnianie formularza...');
    
    try {
      const response = await fetch('/api/fill-form', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          url: url,
          cv_path: selectedCv,
          model_id: selectedModel
        }),
      });
      
      const data = await response.json();
      
      if (data.success) {
        setStatus('success');
        setMessage('Formularz został wypełniony pomyślnie!');
        
        // Odśwież historię
        fetch('/api/history')
          .then(res => res.json())
          .then(data => {
            setHistory(data.history);
          });
      } else {
        setStatus('error');
        setMessage(`Błąd: ${data.message}`);
      }
    } catch (error) {
      setStatus('error');
      setMessage(`Błąd: ${error.message}`);
    }
  };

  const toggleVoiceRecognition = () => {
    if (recording) {
      // Zatrzymaj nagrywanie
      fetch('/api/voice/stop', { method: 'POST' })
        .then(res => res.json())
        .then(data => {
          setRecording(false);
          if (data.command) {
            setMessage(`Wykryto komendę: ${data.command}`);
          }
        });
    } else {
      // Rozpocznij nagrywanie
      fetch('/api/voice/start', { method: 'POST' })
        .then(() => {
          setRecording(true);
          setMessage('Nasłuchuję... Powiedz komendę');
        });
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>coBoarding</h1>
        <p>System do automatycznego wypełniania formularzy rekrutacyjnych</p>
      </header>
      
      <main>
        <section className="form-section">
          <h2>Wypełnij formularz</h2>
          
          <div className="form-group">
            <label>Wybierz CV:</label>
            <select value={selectedCv} onChange={e => setSelectedCv(e.target.value)}>
              {cvFiles.map((file, i) => (
                <option key={i} value={file}>{file}</option>
              ))}
            </select>
          </div>
          
          <div className="form-group">
            <label>URL formularza:</label>
            <input 
              type="text" 
              value={url} 
              onChange={e => setUrl(e.target.value)} 
              placeholder="https://example.com/job-application"
            />
          </div>
          
          <div className="form-group">
            <label>Model LLM:</label>
            <select value={selectedModel} onChange={e => setSelectedModel(e.target.value)}>
              {models.map((model, i) => (
                <option key={i} value={model.id}>
                  {model.name} - {model.description}
                </option>
              ))}
            </select>
          </div>
          
          <button onClick={handleFillForm} disabled={status === 'loading'}>
            {status === 'loading' ? 'Wypełnianie...' : 'Wypełnij formularz'}
          </button>
          
          <button 
            className={recording ? 'recording' : ''} 
            onClick={toggleVoiceRecognition}
          >
            {recording ? 'Zatrzymaj nasłuchiwanie' : 'Sterowanie głosowe'}
          </button>
          
          {message && (
            <div className={`message ${status}`}>
              {message}
            </div>
          )}
        </section>
        
        <section className="preview-section">
          <h2>Podgląd przeglądarki</h2>
          <iframe 
            src="http://localhost:8082"
            title="Browser Preview" 
            className="browser-preview"
          ></iframe>
        </section>
        
        <section className="history-section">
          <h2>Historia wypełnionych formularzy</h2>
          <table>
            <thead>
              <tr>
                <th>Data</th>
                <th>URL</th>
                <th>Status</th>
                <th>Akcje</th>
              </tr>
            </thead>
            <tbody>
              {history.map((item, i) => (
                <tr key={i}>
                  <td>{new Date(item.timestamp).toLocaleString()}</td>
                  <td>{item.url}</td>
                  <td>
                    <span className={`status-badge ${item.status}`}>
                      {item.status}
                    </span>
                  </td>
                  <td>
                    <button onClick={() => window.open(item.screenshot, '_blank')}>
                      Zrzut ekranu
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      </main>
    </div>
  );
}

export default App;