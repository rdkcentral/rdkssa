#!/bin/bash
set -x
set -e

export PATH=/usr/local/bin:$PATH

GITHUB_WORKSPACE="${PWD}"
ls -la "${GITHUB_WORKSPACE}"

echo "building rdkssa"
cd "${GITHUB_WORKSPACE}"

# Resolve Safe C Library compiler and linker flags from the CI image.
SAFEC_CFLAGS="$(pkg-config --cflags libsafec)"
SAFEC_LIBS="$(pkg-config --libs libsafec)"

echo "Safe C Library CFLAGS: ${SAFEC_CFLAGS}"
echo "Safe C Library LIBS: ${SAFEC_LIBS}"

echo "Running autoreconf..."
autoreconf -i

echo "Running configure..."
./configure \
    --prefix="${GITHUB_WORKSPACE}/install/usr" \
    CFLAGS="-fvisibility=default" \
    CPPFLAGS="${SAFEC_CFLAGS}" \
    LIBS="${SAFEC_LIBS}"

echo "Building with make..."
make

echo "Installing..."
make install

echo "======================================================================================"
echo "Build completed successfully"
exit 0
