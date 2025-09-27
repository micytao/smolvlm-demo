# Use CentOS Stream 9 as base image
FROM quay.io/centos/centos:stream9

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Install EPEL and enable CRB (CodeReady Builder) repository
RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf config-manager --set-enabled crb

# Install dependencies
RUN dnf -y install --allowerasing \
    wget \
    git \
    cmake \
    python3 \
    python3-pip \
    python3-devel \
    nginx \
    supervisor \
    gcc \
    gcc-c++ \
    make \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    which \
    tar \
    gzip \
    zlib-devel \
    openssl-devel \
    libcurl-devel \
    && dnf clean all

# Create app directory
WORKDIR /app

# Clone and build llama.cpp with platform-specific optimizations
RUN git clone https://github.com/ggml-org/llama.cpp.git && \
    cd llama.cpp && \
    echo "Configuring cmake..." && \
    cmake -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLAMA_NATIVE=OFF \
      -DLLAMA_BUILD_TESTS=OFF \
      -DLLAMA_BUILD_EXAMPLES=OFF \
      -DCMAKE_VERBOSE_MAKEFILE=ON && \
    echo "Starting build..." && \
    cmake --build build --config Release --target llama-server -j$(nproc) --verbose

# Copy web application files
COPY index.html /app/web/

# Create nginx configuration for serving static files
RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled && \
    rm -f /etc/nginx/sites-enabled/default

COPY nginx.conf /etc/nginx/sites-available/smolvlm
RUN ln -s /etc/nginx/sites-available/smolvlm /etc/nginx/sites-enabled/ && \
    rm -f /etc/nginx/nginx.conf

# Create a simple nginx.conf that includes our site
RUN echo 'user nginx;' > /etc/nginx/nginx.conf && \
    echo 'worker_processes auto;' >> /etc/nginx/nginx.conf && \
    echo 'error_log /var/log/nginx/error.log;' >> /etc/nginx/nginx.conf && \
    echo 'pid /run/nginx.pid;' >> /etc/nginx/nginx.conf && \
    echo 'events { worker_connections 1024; }' >> /etc/nginx/nginx.conf && \
    echo 'http {' >> /etc/nginx/nginx.conf && \
    echo '    include /etc/nginx/mime.types;' >> /etc/nginx/nginx.conf && \
    echo '    default_type application/octet-stream;' >> /etc/nginx/nginx.conf && \
    echo '    include /etc/nginx/sites-enabled/*;' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf

# Create supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Create directory for models
RUN mkdir -p /app/models

# Expose ports
EXPOSE 8080 80

# Use supervisor to run both services
CMD ["/app/start.sh"]
