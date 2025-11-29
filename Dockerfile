# Use official Ubuntu as base (lightweight)
FROM ubuntu:22.04

# Install required tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Download and extract the latest gfx1151 Ubuntu zip from lemonade-sdk/llamacpp-rocm
RUN LATEST_URL=$(curl -s https://api.github.com/repos/lemonade-sdk/llamacpp-rocm/releases/latest | \
                 grep "browser_download_url.*ubuntu.*gfx1151.*zip" | \
                 head -n 1 | \
                 cut -d '"' -f 4) && \
    echo "Downloading: $LATEST_URL" && \
    curl -L -o llama.zip "$LATEST_URL" && \
    unzip llama.zip && \
    rm llama.zip

# Make binary executable (adjust name if needed — usually 'llama-cli' or similar)
RUN chmod +x ./llama-*

# Set entrypoint (optional — adjust based on actual binary name)

