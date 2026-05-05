FROM ubuntu:24.04
# stet
ARG LLAMACPP_ROCM_TAG=b1253
ARG LLAMACPP_ROCM_ARCH=gfx1151

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    sed -i 's|http://archive.ubuntu.com/ubuntu|https://azure.archive.ubuntu.com/ubuntu|g; s|http://security.ubuntu.com/ubuntu|https://azure.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        libgomp1 \
        libnuma1 \
        ocl-icd-libopencl1 \
        pciutils; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN set -eux; \
    ASSET="llama-${LLAMACPP_ROCM_TAG}-ubuntu-rocm-${LLAMACPP_ROCM_ARCH}-x64"; \
    curl -fsSL \
      --retry 5 \
      --retry-delay 5 \
      --retry-all-errors \
      -o /tmp/llamacpp-rocm.zip \
      "https://github.com/lemonade-sdk/llamacpp-rocm/releases/download/${LLAMACPP_ROCM_TAG}/${ASSET}.zip"; \
    unzip -q /tmp/llamacpp-rocm.zip -d /opt; \
    rm -f /tmp/llamacpp-rocm.zip; \
    test -x "/opt/${ASSET}/llama-server" || chmod +x "/opt/${ASSET}/llama-server"; \
    find "/opt/${ASSET}" -maxdepth 1 -type f -name "llama-*" -exec chmod +x {} \; ; \
    ln -sf "/opt/${ASSET}/llama-server" /usr/local/bin/llama-server; \
    ln -sf "/opt/${ASSET}/llama-cli" /usr/local/bin/llama-cli || true; \
    ln -sf "/opt/${ASSET}/llama-bench" /usr/local/bin/llama-bench || true; \
    ln -sf "/opt/${ASSET}/rpc-server" /usr/local/bin/rpc-server || true

ENV LLAMA_CPP_DIR=/opt/llama-b1253-ubuntu-rocm-gfx1151-x64
ENV PATH="${LLAMA_CPP_DIR}:${PATH}"
ENV LD_LIBRARY_PATH="${LLAMA_CPP_DIR}:${LLAMA_CPP_DIR}/lib:${LLAMA_CPP_DIR}/rocm/lib:${LLAMA_CPP_DIR}/rocm/lib64"

EXPOSE 8080

ENTRYPOINT ["llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080"]
