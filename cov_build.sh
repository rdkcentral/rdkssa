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
apt-get install -y libsafec-dev

# Check if safec headers are installed
echo "Checking for safec_lib.h..."
if [ -f "/usr/include/safec/safec_lib.h" ]; then
    echo "Found safec_lib.h at /usr/include/safec/"
elif [ -f "/usr/include/safec_lib.h" ]; then
    echo "Found safec_lib.h at /usr/include/"
else
    echo "Warning: safec_lib.h not found in standard locations"
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

