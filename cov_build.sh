#!/bin/bash
set -e
##############################
export PATH=/usr/local/bin:$PATH

GITHUB_WORKSPACE="${PWD}"
ls -la ${GITHUB_WORKSPACE}

############################
# Install build dependencies
echo "Installing build dependencies..."
apt-get update
apt-get install -y libsafec libsafec-dev pkg-config

# Verify safec installation and find its locations
echo "Verifying safec installation..."
if pkg-config --exists libsafec; then
    echo "Found libsafec via pkg-config"
    SAFEC_CFLAGS=$(pkg-config --cflags libsafec)
    SAFEC_LIBS=$(pkg-config --libs libsafec)
    echo "SAFEC_CFLAGS: $SAFEC_CFLAGS"
    echo "SAFEC_LIBS: $SAFEC_LIBS"
else
    echo "Warning: libsafec not found via pkg-config, using default paths"
    SAFEC_CFLAGS="-I/usr/include/safec"
    SAFEC_LIBS="-lsafec"
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
    CPPFLAGS="$SAFEC_CFLAGS" \
    CFLAGS="-fvisibility=default" \
    CXXFLAGS="-fvisibility=default" \
    LIBS="$SAFEC_LIBS"

echo "Building with make..."
make

echo "Installing..."
make install

echo "======================================================================================"
echo "Build completed successfully"
exit 0
