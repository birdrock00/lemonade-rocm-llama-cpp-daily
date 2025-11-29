FROM ubuntu:24.04

EXPOSE 8080

# Install only what's needed
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg unzip libatomic1 libgomp1 libnuma1 && \
    rm -rf /var/lib/apt/lists/*

# Add ROCm 7.0 repo
RUN curl -fsSL https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /usr/share/keyrings/rocm.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.0 noble main" \
        > /etc/apt/sources.list.d/rocm.list

# Install MINIMAL ROCm runtime (no dev tools!)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        hip-runtime-amd \
        comgr \
        hsa-rocr-dev \
        && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV ROCM_PATH=/opt/rocm
ENV PATH=$ROCM_PATH/bin:$PATH
ENV LD_LIBRARY_PATH=$ROCM_PATH/lib:$LD_LIBRARY_PATH

WORKDIR /app
RUN mkdir -p /models

# Download & extract
RUN LATEST_URL=$(curl -s https://api.github.com/repos/lemonade-sdk/llamacpp-rocm/releases/latest | \
                 grep "browser_download_url.*ubuntu.*gfx1151.*zip" | head -n1 | cut -d'"' -f4) && \
    echo "URL: $LATEST_URL" && \
    curl -L -o llama.zip "$LATEST_URL" && \
    unzip llama.zip && \
    rm llama.zip && \
    chmod +x ./llama-*
