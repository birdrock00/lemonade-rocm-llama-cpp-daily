# Use AMD's recommended base: Ubuntu 24.04
FROM ubuntu:24.04

# Expose server port
EXPOSE 8080

# Install base tools and GPG key for ROCm repo
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        unzip \
        && rm -rf /var/lib/apt/lists/*

# Add ROCm 7.0 official repository
RUN curl -fsSL https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /usr/share/keyrings/rocm.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.0 noble main" \
        > /etc/apt/sources.list.d/rocm.list

# Install ROCm runtime and essential system libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        rocm-libs \
        hip-runtime-amd \
        libatomic1 \
        libgomp1 \
        libnuma1 \
        && rm -rf /var/lib/apt/lists/*

# Set ROCm environment variables
ENV ROCM_PATH=/opt/rocm
ENV PATH=$ROCM_PATH/bin:$PATH
ENV LD_LIBRARY_PATH=$ROCM_PATH/lib:$LD_LIBRARY_PATH

# Create application directory
WORKDIR /app

# Create models directory for easy mounting
RUN mkdir -p /models

# Download and extract the latest gfx1151 Ubuntu binary from Lemonade SDK
RUN LATEST_URL=$(curl -s https://api.github.com/repos/lemonade-sdk/llamacpp-rocm/releases/latest | \
                 grep "browser_download_url.*ubuntu.*gfx1151.*zip" | \
                 head -n 1 | \
                 cut -d '"' -f 4) && \
    echo "Downloading: $LATEST_URL" && \
    curl -L -o llama.zip "$LATEST_URL" && \
    unzip llama.zip && \
    rm llama.zip

# Make all extracted binaries executable
RUN chmod +x ./llama-*
