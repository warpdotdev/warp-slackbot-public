# syntax=docker/dockerfile:1

FROM debian:trixie-slim

# Set working directory
WORKDIR /app

# Set architecture variable for Warp CLI (build-time only)
ARG TARGETARCH
ARG CHANNEL 

# Copy Python requirements first for better caching
COPY requirements.txt .

# Install system dependencies, Python, git, and Warp CLI
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    curl \
    git \
    ca-certificates \
    libcurl4 \
    gnupg \
    jq \
    zsh && \
    # Install yq for YAML processing
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq && \
    # Install GitHub CLI
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=${TARGETARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y gh && \
    # Create and activate virtual environment
    python3 -m venv /app/venv && \
    # Activate venv and install dependencies
    /app/venv/bin/pip install --no-cache-dir -r requirements.txt && \
    # Install Warp CLI using architecture-specific download (staging URL for dev channel)
    if [ "$CHANNEL" = "dev" ]; then \
        echo "Installing Warp CLI dev version..." && \
        wget --output-document=warp-cli.deb "https://staging.warp.dev/download/cli?os=linux&package=deb&channel=dev&arch=${TARGETARCH}"; \
    else \
        echo "Installing Warp CLI prod version..." && \
        wget --output-document=warp-cli.deb "https://app.warp.dev/download/cli?os=linux&package=deb&arch=${TARGETARCH}"; \
    fi && \
    dpkg -i warp-cli.deb || (apt-get update && apt-get install -f -y) && \
    dpkg -i warp-cli.deb && \
    (which warp-cli || which warp-cli-dev) && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives warp-cli.deb

# Copy application code and setup script
COPY app.py .
COPY prompt.py .
COPY slack_send.sh .
COPY setup.sh .
COPY repos.yaml .
RUN chmod +x setup.sh

# Create non-root user with zsh shell
RUN useradd -ms /bin/zsh --uid 1001 slack-app
# Create volume mount directories and change ownership
RUN mkdir -p /app/repos /app/logs && chown -R slack-app:slack-app /app
USER slack-app

# Warp CLI is now installed and ready to use

# Slack environment variables (SLACK_BOT_TOKEN and SLACK_APP_TOKEN)
# should be provided at runtime via docker-compose


# Set Python to unbuffered mode for immediate output
ENV PYTHONUNBUFFERED=1

# Run the setup script which clones repos and starts the Python application
CMD ["/app/setup.sh"]

