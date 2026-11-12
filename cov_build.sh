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
if find /usr -name "safec_lib.h" 2>/dev/null | head -1; then
    SAFEC_PATH=$(find /usr -name "safec_lib.h" 2>/dev/null | head -1 | xargs dirname)
    echo "Found SafeC headers at: $SAFEC_PATH"
    SAFEC_FLAGS="-I${SAFEC_PATH}"
else
    echo "WARNING: SafeC headers not found"
    SAFEC_FLAGS=""
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
	
