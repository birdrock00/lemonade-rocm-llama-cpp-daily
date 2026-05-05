FROM ubuntu:24.04

ARG LLAMACPP_ROCM_TAG=b1253
ARG LLAMACPP_ROCM_ARCH=gfx1151

ENV DEBIAN_FRONTEND=noninteractive
ENV LLAMA_CPP_DIR=/opt/llamacpp
ENV PATH="${LLAMA_CPP_DIR}:${PATH}"
ENV LD_LIBRARY_PATH="${LLAMA_CPP_DIR}:${LLAMA_CPP_DIR}/lib:${LLAMA_CPP_DIR}/rocm/lib:${LLAMA_CPP_DIR}/rocm/lib64"

RUN cat > /etc/apt/sources.list.d/ubuntu.sources <<'EOF'
Types: deb
URIs: http://azure.archive.ubuntu.com/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://azure.archive.ubuntu.com/ubuntu
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

RUN set -eux; \
    for i in 1 2 3 4 5; do \
      apt-get -o Acquire::Retries=5 update \
      && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        libatomic1 \
        libgomp1 \
        libnuma1 \
        ocl-icd-libopencl1 \
        pciutils \
      && break; \
      echo "apt failed, retrying in 15s..."; \
      sleep 15; \
    done; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN set -eux; \
    ASSET="llama-${LLAMACPP_ROCM_TAG}-ubuntu-rocm-${LLAMACPP_ROCM_ARCH}-x64"; \
    mkdir -p "${LLAMA_CPP_DIR}"; \
    curl -fsSL \
      --retry 5 \
      --retry-delay 5 \
      --retry-all-errors \
      -o /tmp/llamacpp-rocm.zip \
      "https://github.com/lemonade-sdk/llamacpp-rocm/releases/download/${LLAMACPP_ROCM_TAG}/${ASSET}.zip"; \
    unzip -q /tmp/llamacpp-rocm.zip -d "${LLAMA_CPP_DIR}"; \
    rm -f /tmp/llamacpp-rocm.zip; \
    test -f "${LLAMA_CPP_DIR}/llama-server"; \
    find "${LLAMA_CPP_DIR}" -maxdepth 1 -type f \( -name "llama-*" -o -name "rpc-server" \) -exec chmod +x {} \; ; \
    for tool in llama-server llama-cli llama-bench rpc-server; do \
      if [ -f "${LLAMA_CPP_DIR}/${tool}" ]; then \
        ln -sf "${LLAMA_CPP_DIR}/${tool}" "/usr/local/bin/${tool}"; \
      fi; \
    done

EXPOSE 8080

ENTRYPOINT ["llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080"]
