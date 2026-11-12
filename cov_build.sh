#!/bin/bash
set -e
##############################
export PATH=/usr/local/bin:$PATH

GITHUB_WORKSPACE="${PWD}"
ls -la ${GITHUB_WORKSPACE}

############################
# Install build tools and dependencies
echo "Installing build tools and dependencies..."
apt-get update
apt-get install -y build-essential autoconf automake libtool pkg-config

# SafeC library (check if available)
echo "Checking for SafeC library..."
if apt-cache search libsafec-dev >/dev/null 2>&1; then
    apt-get install -y libsafec-dev
fi

# Check if SafeC headers exist
if [ -f "/usr/include/safec/safec_lib.h" ]; then
    echo "SafeC headers found at /usr/include/safec/"
    SAFEC_FLAGS="-I/usr/include/safec"
elif [ -f "/usr/include/safec_lib.h" ]; then
    echo "SafeC headers found at /usr/include/"
    SAFEC_FLAGS=""
else
    echo "WARNING: SafeC headers not found, attempting to locate..."
    find /usr -name "safec_lib.h" 2>/dev/null || true
    SAFEC_FLAGS=""
fi

############################
# Build rdkssa
echo "building rdkssa"

cd ${GITHUB_WORKSPACE}

# Configure and build using autotools
echo "Running autoreconf..."
autoreconf -i

echo "Running configure..."
./configure \
    --prefix="${GITHUB_WORKSPACE}/install/usr" \
    CPPFLAGS="-I/usr/include/safec" \
    CFLAGS="-fvisibility=default" \
    CXXFLAGS="-fvisibility=default" \
    LIBS="-lsafec"

echo "Building with make..."
make

echo "Installing..."
make install

echo "======================================================================================"
echo "Build completed successfully"
exit 0
	
