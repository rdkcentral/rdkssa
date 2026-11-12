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

# Verify SafeC installation and get correct paths via pkg-config
echo "Checking SafeC installation..."
if command -v pkg-config &> /dev/null; then
    echo "Using pkg-config to find SafeC..."
    SAFEC_CFLAGS=$(pkg-config --cflags libsafec 2>/dev/null || echo "")
    SAFEC_LIBS=$(pkg-config --libs libsafec 2>/dev/null || echo "-lsafec")
    if [ -n "$SAFEC_CFLAGS" ]; then
        echo "SafeC CFLAGS: $SAFEC_CFLAGS"
        echo "SafeC LIBS: $SAFEC_LIBS"
    else
        echo "pkg-config failed, falling back to defaults"
        SAFEC_CFLAGS="-I/usr/include"
        SAFEC_LIBS="-lsafec"
    fi
else
    echo "pkg-config not found, using defaults"
    SAFEC_CFLAGS="-I/usr/include"
    SAFEC_LIBS="-lsafec"
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
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH
./configure \
    --prefix="${GITHUB_WORKSPACE}/install/usr" \
    CPPFLAGS="${SAFEC_CFLAGS}" \
    CFLAGS="-fvisibility=default" \
    CXXFLAGS="-fvisibility=default" \
    LDFLAGS="-L/usr/lib/x86_64-linux-gnu" \
    LIBS="${SAFEC_LIBS}"

echo "Building with make..."
make

echo "Installing..."
make install

echo "======================================================================================"
echo "Build completed successfully"
exit 0
	
