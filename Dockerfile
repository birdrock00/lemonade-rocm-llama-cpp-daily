FROM ubuntu:24.04

ARG LLAMACPP_ROCM_ARCH=gfx1151

ENV DEBIAN_FRONTEND=noninteractive
ENV LLAMA_CPP_DIR=/opt/llamacpp
ENV PATH="${LLAMA_CPP_DIR}:${PATH}"
ENV LD_LIBRARY_PATH="${LLAMA_CPP_DIR}:${LLAMA_CPP_DIR}/lib:${LLAMA_CPP_DIR}/rocm/lib:${LLAMA_CPP_DIR}/rocm/lib64"

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      unzip \
      libatomic1 \
      libgomp1 \
      libnuma1 \
      ocl-icd-libopencl1 \
      pciutils; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Use the ROCm runtime shipped with the Lemonade artifact. Loading a separate
# system ROCm runtime can mix incompatible libraries with the daily binary.
RUN set -eux; \
    LATEST_URL="$(curl -fsSL https://api.github.com/repos/lemonade-sdk/llamacpp-rocm/releases/latest \
      | grep "browser_download_url.*ubuntu-rocm-${LLAMACPP_ROCM_ARCH}-x64.zip" \
      | head -n1 \
      | cut -d'"' -f4)"; \
    test -n "${LATEST_URL}"; \
    mkdir -p "${LLAMA_CPP_DIR}"; \
    curl -fsSL \
      --retry 5 \
      --retry-delay 5 \
      --retry-all-errors \
      -o /tmp/llamacpp-rocm.zip \
      "${LATEST_URL}"; \
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
