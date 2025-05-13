// Funkcja konfiguracji widoku pipeline'ów
export function setupPipelineViewer(socket) {
  const pipelineContent = document.getElementById('pipeline-content');

  // Obsługa aktualizacji pipeline'a
  socket.on('pipeline_update', (data) => {
    if (data.pipeline) {
      renderPipeline(data.pipeline);
    }
  });

  // Funkcja renderująca pipeline
  function renderPipeline(pipeline) {
    // Czyszczenie bieżącej zawartości
    pipelineContent.innerHTML = '';

    // Tworzenie nagłówka
    const header = document.createElement('div');
    header.className = 'pipeline-header';
    header.innerHTML = `
      <h3>${pipeline.name || 'Pipeline'}</h3>
      <div class="pipeline-url">${pipeline.url || ''}</div>
    `;
    pipelineContent.appendChild(header);

    // Tworzenie listy kroków
    const stepsList = document.createElement('ul');
    stepsList.className = 'pipeline-steps';

    if (pipeline.steps && pipeline.steps.length > 0) {
      pipeline.steps.forEach((step, index) => {
        const stepItem = document.createElement('li');
        stepItem.className = `pipeline-step ${step.status || 'pending'}`;

        let stepContent = `
          <div class="step-header">
            <span class="step-number">${index + 1}</span>
            <span class="step-type">${step.type}</span>
            <span class="step-status">${step.status || 'Pending'}</span>
          </div>
        `;

        // Dodatkowa zawartość w zależności od typu kroku
        if (step.type === 'navigation') {
          stepContent += `<div class="step-details">URL: ${step.url}</div>`;
        } else if (step.type === 'form_filling') {
          stepContent += `<div class="step-details">Fields: ${Object.keys(step.fields || {}).length}</div>`;
        } else if (step.type === 'authentication') {
          stepContent += `<div class="step-details">Login required</div>`;
        } else if (step.type === 'file_upload') {
          stepContent += `<div class="step-details">Files: ${Array.isArray(step.files) ? step.files.length : 0}</div>`;
        }

        stepItem.innerHTML = stepContent;
        stepsList.appendChild(stepItem);
      });
    } else {
      stepsList.innerHTML = '<li class="pipeline-no-steps">No steps defined</li>';
    }

    pipelineContent.appendChild(stepsList);

    // Dodanie przycisków akcji
    const actions = document.createElement('div');
    actions.className = 'pipeline-actions';
    actions.innerHTML = `
      <button class="action-button run-button">Run Pipeline</button>
      <button class="action-button edit-button">Edit Pipeline</button>
    `;
    pipelineContent.appendChild(actions);

    // Dodanie obsługi zdarzeń dla przycisków
    const runButton = actions.querySelector('.run-button');
    runButton.addEventListener('click', () => {
      socket.emit('voice_command', {
        command: 'run_pipeline',
        params: { pipeline_id: pipeline.id || pipeline.name }
      });
    });

    const editButton = actions.querySelector('.edit-button');
    editButton.addEventListener('click', () => {
      socket.emit('voice_command', {
        command: 'edit_pipeline',
        params: { pipeline_id: pipeline.id || pipeline.name }
      });
    });
  }
}