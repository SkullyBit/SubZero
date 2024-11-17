# Use a stable base image
FROM ubuntu:22.04

# Set environment variables to minimize interaction during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV VIRTUAL_ENV=/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install core development tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-11 \
    g++-11 \
    cmake \
    pkg-config \
    libglib2.0-dev \
    libxml2-dev \
    libncurses5-dev \
    libevent-dev \
    zlib1g-dev \
    python3 \
    python3-pip \
    python3-venv \
    python3-yaml \
    git \
    xxd \
    grep \
    findutils \
    sed \
    gawk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set GCC/G++ version explicitly
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100

# Verify versions
RUN gcc --version && g++ --version && cmake --version

# Set the working directory
WORKDIR /usr/src/SubZero

# Create and activate a Python virtual environment
RUN python3 -m venv $VIRTUAL_ENV

# Install Python dependencies into the virtual environment
RUN pip install --no-cache-dir pytest pyyaml

# Copy the entire project into the container, excluding files in .dockerignore
COPY . .

# Ensure required scripts are executable
RUN chmod +x tools/gen-version-file \
    tools/gen-test-runner \
    tools/gen-test-proto \
    tools/fix/fixdialectc

# Add virtual environment activation to bashrc
RUN echo "source $VIRTUAL_ENV/bin/activate" >> ~/.bashrc

# Build the project using CMake with verbose output
RUN cmake -S . -B build -G "Unix Makefiles" -DCMAKE_CXX_STANDARD=20 -DCMAKE_CXX_STANDARD_REQUIRED=ON
RUN cmake --build build

# Run C++ tests
RUN cd build && ctest --output-on-failure

# Default command when the container is run
CMD ["/bin/bash"]
