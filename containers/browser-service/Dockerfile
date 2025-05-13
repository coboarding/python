FROM debian:bullseye-slim

# Temporarily redirect interactive dialogs during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y xvfb
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    tigervnc-standalone-server \
    tigervnc-common \
    fluxbox \
    xterm \
    x11-xserver-utils \
    dbus-x11 \
    libglib2.0-0 \
    libnss3 \
    libx11-xcb1 \
    libxtst6 \
    libxss1 \
    libgbm1 \
    libasound2 \
    fonts-noto-color-emoji \
    fonts-noto-core \
    xdg-utils \
    wget \
    curl \
    gnupg \
    supervisor \
    ffmpeg \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome (new way to add the key)
RUN set -eux; \
    echo '[DEBUG] Creating directory for Chrome GPG key...'; \
    mkdir -p /etc/apt/keyrings; \
    echo '[DEBUG] Downloading Chrome GPG key...'; \
    wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/keyrings/google-linux-signing-key.gpg; \
    echo '[DEBUG] Adding Chrome repository to sources.list...'; \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list; \
    echo '[DEBUG] apt-get update'; \
    apt-get update; \
    echo '[DEBUG] Installing google-chrome-stable'; \
    apt-get install -y --no-install-recommends google-chrome-stable; \
    echo '[DEBUG] apt-get clean'; \
    apt-get clean; \
    echo '[DEBUG] Cleaning apt cache'; \
    rm -rf /var/lib/apt/lists/*; \
    echo '[DEBUG] Chrome installation completed.'

# Install Firefox
RUN echo '[DEBUG] Installing Firefox...'; \
    apt-get update && apt-get install -y --no-install-recommends \
    firefox-esr \
    && rm -rf /var/lib/apt/lists/*; \
    echo '[DEBUG] Firefox installation completed.'

# Install ChromeDriver with better fallback mechanism
# Install ChromeDriver with improved fallback mechanism
RUN set -eux; \
    echo '[DEBUG] Installing ChromeDriver...'; \
    CHROME_VERSION=$(google-chrome --version | awk '{print $3}'); \
    CHROME_MAJOR_VERSION=$(echo $CHROME_VERSION | cut -d '.' -f 1); \
    echo "[DEBUG] Detected Chrome version: ${CHROME_VERSION} (Major: ${CHROME_MAJOR_VERSION})"; \
    if curl -s -f "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION}" > /dev/null; then \
        CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION}"); \
        echo "[DEBUG] Found matching ChromeDriver version: ${CHROMEDRIVER_VERSION}"; \
    else \
        echo "[DEBUG] No specific ChromeDriver for Chrome ${CHROME_MAJOR_VERSION}, using latest release"; \
        CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE"); \
        if [ -z "$CHROMEDRIVER_VERSION" ] || [[ "$CHROMEDRIVER_VERSION" == *"<?xml"* ]]; then \
            echo "[DEBUG] Failed to get latest release, using fixed version"; \
            CHROMEDRIVER_VERSION="114.0.5735.90"; \
        fi; \
    fi; \
    echo "[DEBUG] Using ChromeDriver version: ${CHROMEDRIVER_VERSION}"; \
    # Try downloading from the standard location
    if wget -q --spider "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"; then \
        wget -q "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"; \
    # Try alternative location (newer Chrome versions)
    elif wget -q --spider "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROMEDRIVER_VERSION}/linux64/chromedriver-linux64.zip"; then \
        wget -q "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROMEDRIVER_VERSION}/linux64/chromedriver-linux64.zip" -O chromedriver_linux64.zip; \
    # Fall back to known working version
    else \
        echo "[DEBUG] Falling back to known working version 114.0.5735.90"; \
        wget -q "https://chromedriver.storage.googleapis.com/114.0.5735.90/chromedriver_linux64.zip"; \
    fi; \
    # Handle different archive structures
    mkdir -p /tmp/chromedriver; \
    unzip -q chromedriver_linux64.zip -d /tmp/chromedriver; \
    if [ -f /tmp/chromedriver/chromedriver ]; then \
        mv /tmp/chromedriver/chromedriver /usr/local/bin/; \
    elif [ -d /tmp/chromedriver/chromedriver-linux64 ]; then \
        mv /tmp/chromedriver/chromedriver-linux64/chromedriver /usr/local/bin/; \
    else \
        find /tmp/chromedriver -name "chromedriver" -type f -exec mv {} /usr/local/bin/ \; ; \
    fi; \
    rm -rf /tmp/chromedriver chromedriver_linux64.zip; \
    chmod +x /usr/local/bin/chromedriver; \
    echo '[DEBUG] ChromeDriver installation completed.'

# Install GeckoDriver (Firefox)
RUN set -eux; \
    echo '[DEBUG] Installing jq for parsing JSON...'; \
    apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/*; \
    echo '[DEBUG] Installing GeckoDriver...'; \
    GECKO_DRIVER_VERSION=$(curl -s https://api.github.com/repos/mozilla/geckodriver/releases/latest | jq -r .tag_name); \
    echo "[DEBUG] GeckoDriver version: $GECKO_DRIVER_VERSION"; \
    wget -q "https://github.com/mozilla/geckodriver/releases/download/${GECKO_DRIVER_VERSION}/geckodriver-${GECKO_DRIVER_VERSION}-linux64.tar.gz"; \
    tar -xzf "geckodriver-${GECKO_DRIVER_VERSION}-linux64.tar.gz" -C /usr/local/bin; \
    rm "geckodriver-${GECKO_DRIVER_VERSION}-linux64.tar.gz"; \
    chmod +x /usr/local/bin/geckodriver; \
    echo '[DEBUG] GeckoDriver installation completed.'

# Install CLI password managers
RUN echo '[DEBUG] Installing Bitwarden CLI...'; \
    curl -fsSL https://get.bitwarden.com/sh | bash; \
    echo '[DEBUG] Bitwarden CLI installation completed.'

# Create directory structure
RUN echo '[DEBUG] Creating application directory structure...'; \
    mkdir -p /app/cv /app/config /app/passwords /app/recordings /app/scripts \
    && mkdir -p /opt/scripts \
    && mkdir -p /root/.vnc \
    && mkdir -p /var/log/supervisor; \
    echo '[DEBUG] Directory structure created.'

# Copy scripts
COPY scripts/ /opt/scripts/
RUN echo '[DEBUG] Setting execution permissions for .sh scripts...'; \
    chmod +x /opt/scripts/*.sh; \
    echo '[DEBUG] .sh scripts have execution permissions.'

# Copy configuration files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN echo '[DEBUG] Copied supervisord.conf configuration file.'

# Install Python dependencies
COPY requirements.txt /app/
RUN echo '[DEBUG] Installing Python dependencies...'; \
    pip3 install --no-cache-dir -r /app/requirements.txt; \
    echo '[DEBUG] Python dependencies installation completed.'

# Configure TigerVNC
RUN echo '[DEBUG] Configuring TigerVNC...'; \
    mkdir -p /root/.vnc && \
    echo "#!/bin/sh" > /root/.vnc/xstartup && \
    echo "xrdb $HOME/.Xresources" >> /root/.vnc/xstartup && \
    echo "startfluxbox &" >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup; \
    echo '[DEBUG] TigerVNC configuration completed.'

# Set environment variables
ENV DISPLAY=:99
ENV PYTHONUNBUFFERED=1

# Expose VNC port
EXPOSE 5900

# Run supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]