AutoFormFiller-Pro
├── containers
│   ├── browser-service
│   │   ├── Dockerfile
│   │   ├── browsers
│   │   │   ├── chrome-setup.sh
│   │   │   └── firefox-setup.sh
│   │   ├── extensions
│   │   │   ├── chrome
│   │   │   └── firefox
│   │   ├── supervisord.conf
│   │   └── scripts
│   │       └── form-fill.py
│   │
│   ├── llm-orchestrator
│   │   ├── Dockerfile
│   │   ├── api.py
│   │   ├── detect-hardware.py
│   │   ├── pipeline_generator.py
│   │   ├── model-configs
│   │   │   ├── cpu-configs.json
│   │   │   └── gpu-configs.json
│   │   └── data
│   │       └── job_portals_knowledge.json
│   │
│   ├── novnc
│   │   └── Dockerfile
│   │
│   ├── web-terminal
│   │   ├── Dockerfile
│   │   └── startup.sh
│   │
│   ├── test-forms-server
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── forms
│   │       ├── simple-form.html
│   │       ├── complex-form.html
│   │       └── file-upload-form.html
│   │
│   ├── test-runner
│   │   ├── Dockerfile
│   │   └── tests
│   │       ├── run-tests.py
│   │       ├── test-simple-form.py
│   │       ├── test-complex-form.py
│   │       └── test-file-upload.py
│   │
│   └── web-interface
│       ├── Dockerfile
│       ├── nginx.conf
│       ├── package.json
│       ├── src
│       │   ├── App.js
│       │   ├── App.css
│       │   ├── index.js
│       │   ├── index.css
│       │   └── components
│       │       └── VoiceControl.js
│       └── public
│           └── index.html
│
├── volumes
│   ├── cv
│   ├── models
│   ├── config
│   │   └── pipelines
│   ├── passwords
│   └── recordings
│
├── docker-compose.yml
├── .env
├── init.sh
├── run.sh
├── setup-all.sh
├── run-tests.sh
├── requirements.txt
├── config.ini
├── LICENSE
└── README.md