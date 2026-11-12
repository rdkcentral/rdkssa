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

# Try to find and install SafeC
echo "Looking for SafeC library..."

# Check available SafeC packages
echo "Available SafeC packages:"
apt-cache search safec || true

# Try installing libsafec-dev
echo "Attempting to install libsafec-dev..."
apt-get install -y libsafec-dev 2>/dev/null || {
    echo "libsafec-dev not found in standard repos, checking for alternative packages..."
    apt-get install -y libsafec 2>/dev/null || {
        echo "WARNING: SafeC package not found, attempting to build from source..."
        cd /tmp
        git clone https://github.com/rdkcentral/safec.git 2>/dev/null || git clone https://github.com/intel/safec.git || true
        if [ -d "/tmp/safec" ]; then
            cd /tmp/safec
            make -j$(nproc) || make || true
            make install || true
            cd ${GITHUB_WORKSPACE}
        fi
    }
}

# Verify SafeC installation
echo "Checking SafeC installation..."
SAFEC_HEADER=$(find /usr -name "safec_lib.h" -type f 2>/dev/null | head -1)
if [ -n "$SAFEC_HEADER" ]; then
    SAFEC_PATH=$(dirname "$SAFEC_HEADER")
    echo "Found SafeC headers at: $SAFEC_PATH"
    SAFEC_FLAGS="-I${SAFEC_PATH}"
else
    echo "WARNING: SafeC headers not found via find, checking standard locations..."
    if [ -f "/usr/include/safec_lib.h" ]; then
        echo "Found at /usr/include/safec_lib.h"
        SAFEC_FLAGS=""
    elif [ -f "/usr/include/safec/safec_lib.h" ]; then
        echo "Found at /usr/include/safec/safec_lib.h"
        SAFEC_FLAGS="-I/usr/include/safec"
    else
        echo "SafeC headers not found in standard locations"
        SAFEC_FLAGS=""
    fi
fi

# Check for SafeC libraries
if find /usr -name "libsafec*" 2>/dev/null | head -1; then
    echo "Found SafeC libraries:"
    find /usr -name "libsafec*" 2>/dev/null || true
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
	LDFLAGS="-L/usr/lib -L/usr/local/lib" \
    LIBS="-lsafec"

echo "Building with make..."
make

echo "Installing..."
make install

echo "======================================================================================"
echo "Build completed successfully"
exit 0
	
