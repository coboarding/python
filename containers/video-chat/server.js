const express = require('express');
const https = require('https');
const fs = require('fs');
const path = require('path');
const socketIO = require('socket.io');
const cors = require('cors');
const axios = require('axios');
const { spawn } = require('child_process');
const { v4: uuidv4 } = require('uuid');
const googleTTS = require('google-tts-api');
require('dotenv').config();

// Konfiguracja z zmiennych środowiskowych
const LLM_API_URL = process.env.LLM_API_URL || 'http://llm-orchestrator:5000';
const NOVNC_URL = process.env.NOVNC_URL || 'http://novnc:8080';
const TTS_ENGINE = process.env.TTS_ENGINE || 'google';
const STT_ENGINE = process.env.STT_ENGINE || 'browser';
const PORT = process.env.PORT || 443;

// Inicjalizacja serwera Express
const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'dist')));

// Konfiguracja HTTPS
const httpsOptions = {
  key: fs.readFileSync('./certs/key.pem'),
  cert: fs.readFileSync('./certs/cert.pem')
};

const server = https.createServer(httpsOptions, app);
const io = socketIO(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Ścieżki API

// Proxy do LLM API
app.post('/api/llm/*', async (req, res) => {
  try {
    const endpoint = req.path.replace('/api/llm', '');
    const response = await axios.post(`${LLM_API_URL}${endpoint}`, req.body);
    res.json(response.data);
  } catch (error) {
    console.error('Error proxying to LLM API:', error);
    res.status(500).json({ error: 'Error communicating with LLM API' });
  }
});

// Endpoint do konwersji tekstu na mowę
app.post('/api/tts', async (req, res) => {
  try {
    const { text, language = 'pl-PL' } = req.body;

    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }

    // Generowanie unikalnej nazwy pliku
    const fileName = `${uuidv4()}.mp3`;
    const filePath = path.join(__dirname, 'recordings', fileName);

    // Wybór silnika TTS
    switch (TTS_ENGINE) {
      case 'google':
        // Użycie Google TTS API
        const url = googleTTS.getAudioUrl(text, {
          lang: language.split('-')[0],
          slow: false,
          host: 'https://translate.google.com',
        });

        // Pobieranie pliku audio
        const response = await axios({
          method: 'GET',
          url: url,
          responseType: 'arraybuffer'
        });

        fs.writeFileSync(filePath, response.data);
        break;

      case 'azure':
        // Implementacja Azure TTS możliwa z użyciem SDK
        // Przykładowa implementacja byłaby tutaj
        break;

      case 'local':
        // Użycie lokalnego TTS przez Python
        await new Promise((resolve, reject) => {
          const ttsProcess = spawn('python3', ['./scripts/local_tts.py', text, language, filePath]);

          ttsProcess.on('close', (code) => {
            if (code === 0) {
              resolve();
            } else {
              reject(new Error(`TTS process exited with code ${code}`));
            }
          });
        });
        break;

      default:
        return res.status(400).json({ error: 'Invalid TTS engine specified' });
    }

    // Zwrócenie ścieżki do pliku audio
    res.json({
      success: true,
      audioUrl: `/recordings/${fileName}`
    });

  } catch (error) {
    console.error('Error in TTS:', error);
    res.status(500).json({ error: 'Error generating speech' });
  }
});

// Endpoint do rozpoznawania mowy
app.post('/api/stt', async (req, res) => {
  try {
    if (!req.files || !req.files.audio) {
      return res.status(400).json({ error: 'Audio file is required' });
    }

    const audioFile = req.files.audio;
    const language = req.body.language || 'pl-PL';

    // Zapisanie przesłanego pliku
    const filePath = path.join(__dirname, 'recordings', `${uuidv4()}.wav`);
    await audioFile.mv(filePath);

    let recognizedText = '';

    // Wybór silnika STT
    switch (STT_ENGINE) {
      case 'google':
        // Implementacja Google Speech-to-Text
        // Przykładowa implementacja byłaby tutaj
        break;

      case 'local':
        // Użycie lokalnego STT przez Python
        await new Promise((resolve, reject) => {
          const sttProcess = spawn('python3', ['./scripts/local_stt.py', filePath, language]);

          let stdout = '';
          sttProcess.stdout.on('data', (data) => {
            stdout += data.toString();
          });

          sttProcess.on('close', (code) => {
            if (code === 0) {
              recognizedText = stdout.trim();
              resolve();
            } else {
              reject(new Error(`STT process exited with code ${code}`));
            }
          });
        });
        break;

      default:
        return res.status(400).json({ error: 'Invalid STT engine specified' });
    }

    // Czyszczenie - usunięcie tymczasowego pliku
    fs.unlinkSync(filePath);

    res.json({
      success: true,
      text: recognizedText
    });

  } catch (error) {
    console.error('Error in STT:', error);
    res.status(500).json({ error: 'Error recognizing speech' });
  }
});

// Serwowanie głównej strony
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

// Obsługa WebSocket
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  // Nasłuchiwanie na komendy głosowe
  socket.on('voice_command', async (data) => {
    try {
      const { command, params } = data;

      // Przekazanie komendy do LLM API
      const response = await axios.post(`${LLM_API_URL}/execute_command`, {
        action: command,
        params: params
      });

      // Generowanie odpowiedzi głosowej
      if (response.data.success && response.data.message) {
        const ttsResponse = await axios.post('/api/tts', {
          text: response.data.message,
          language: 'pl-PL'
        });

        if (ttsResponse.data.success) {
          socket.emit('voice_response', {
            audioUrl: ttsResponse.data.audioUrl,
            text: response.data.message
          });
        }
      }

      // Emitowanie aktualizacji pipeline'a jeśli jest dostępny
      if (response.data.pipeline) {
        socket.emit('pipeline_update', {
          pipeline: response.data.pipeline
        });
      }

    } catch (error) {
      console.error('Error processing voice command:', error);
      socket.emit('error', { message: 'Error processing voice command' });
    }
  });

  // Obserwowanie aktualizacji pipeline'ów
  socket.on('subscribe_pipelines', () => {
    // Tu możemy dodać logikę do subskrypcji aktualizacji pipeline'ów
    console.log('Client subscribed to pipeline updates:', socket.id);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Uruchomienie serwera
server.listen(PORT, () => {
  console.log(`Server running on https://localhost:${PORT}`);
});