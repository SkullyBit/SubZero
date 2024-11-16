# Use a stable base image
FROM ubuntu:22.04

# Set environment variables to minimise interaction during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install core development tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    cmake \
    pkg-config \
    libglib2.0-dev \
    libxml2-dev \
    libncurses5-dev \
    libevent-dev \
    zlib1g-dev \
    python3 \
    python3-pip \
    python3-yaml \
    git \
    xxd \
    grep \
    findutils \
    sed \
    gawk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /usr/src/SubZero

# Copy the entire project into the container, excluding files in .dockerignore
COPY . .

# Ensure required scripts are executable
RUN chmod +x tools/gen-version-file \
    tools/gen-test-runner \
    tools/gen-test-proto \
    tools/fix/fixdialectc

# Build the project using CMake
RUN cmake -S . -B build
RUN cmake --build build

# Run tests
RUN cd build && ctest --output-on-failure

# Default command when the container is run
CMD ["/bin/bash"]
