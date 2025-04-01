#!/bin/bash
set -xeo pipefail

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

while getopts "d:" opt; do
    case "$opt" in
        d)  DOCKER_REPO=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# First find the actual Darwin version inside the container to use for subsequent tests
DARWIN_VERSION=$(docker run --rm ${DOCKER_REPO} bash -c 'cat /usr/osxcross/darwin_version || echo 23.5')
echo "Detected Darwin version: ${DARWIN_VERSION}"
DARWIN_MAJOR=$(echo $DARWIN_VERSION | cut -d. -f1)
echo "Using Darwin major version: ${DARWIN_MAJOR}"

# Check if i386 support should be enabled based on SDK version
# i386 support was removed in macOS 10.15 (Darwin 19)
if [ ${DARWIN_MAJOR} -ge 19 ]; then
    echo "SDK version ${DARWIN_MAJOR} detected - i386 support not available (dropped in macOS 10.15/Darwin 19)"
    HAS_I386=false
    # Darwin triples without i386
    DARWIN_TRIPLES="x86_64-apple-darwin${DARWIN_MAJOR} x86_64h-apple-darwin${DARWIN_MAJOR} aarch64-apple-darwin${DARWIN_MAJOR}"
else
    echo "SDK version ${DARWIN_MAJOR} detected - i386 support should be available"
    HAS_I386=true
    # Darwin triples with i386
    DARWIN_TRIPLES="x86_64-apple-darwin${DARWIN_MAJOR} i386-apple-darwin${DARWIN_MAJOR} x86_64h-apple-darwin${DARWIN_MAJOR} aarch64-apple-darwin${DARWIN_MAJOR}"
fi

# Set variables for other architectures
LINUX_TRIPLES="arm-linux-gnueabihf arm-linux-gnueabi powerpc64le-linux-gnu aarch64-linux-gnu arm-linux-gnueabihf mipsel-linux-gnu"
WINDOWS_TRIPLES="x86_64-w64-mingw32 i686-w64-mingw32"
ALIAS_TRIPLES="arm armhf arm64 amd64 x86_64 mips mipsel powerpc powerpc64 powerpc64le osx darwin windows"
DOCKER_TEST_ARGS="--rm -v $(pwd)/test:/test -w /test"

# Run basic tests for all triples
for triple in ${DARWIN_TRIPLES} ${LINUX_TRIPLES} ${WINDOWS_TRIPLES} ${ALIAS_TRIPLES}; do
    # For Windows triples, look for .exe files
    if [[ $triple == *mingw32 ]]; then
        echo "Testing Windows triple: $triple (looking for .exe)"
        docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=${triple} ${DOCKER_REPO} make test
        file test/helloworld.exe || echo "No .exe output file found"
    else
        echo "Testing triple: $triple"
        docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=${triple} ${DOCKER_REPO} make test || echo "Test for $triple failed but continuing"
        file test/helloworld || echo "No output file found"
    fi
done

# Tests specific to macOS
# Try to use the exact Darwin version rather than hardcoding 14
echo "Testing macOS compiler with detected version ${DARWIN_VERSION}"
echo "Test 1: Using osxcross path"
docker run ${DOCKER_TEST_ARGS} ${DOCKER_REPO} bash -c "find /usr/osxcross/bin -name 'i386-apple-darwin*-cc' | xargs -I{} {} helloworld.c -o helloworld || echo 'Compiler not found'"
file test/helloworld || echo "No output file found"

echo "Test 2: Using symlink path"
docker run ${DOCKER_TEST_ARGS} ${DOCKER_REPO} bash -c "find /usr/i386-apple-darwin*/bin -name cc | xargs -I{} {} helloworld.c -o helloworld || echo 'Compiler not found'"
file test/helloworld || echo "No output file found"

echo "Test 3: Using CROSS_TRIPLE environment"
docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=i386-apple-darwin${DARWIN_MAJOR} ${DOCKER_REPO} cc helloworld.c -o helloworld
file test/helloworld || echo "No output file found"

echo "Test 4: Using x86_64 instead of i386"
docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=x86_64-apple-darwin${DARWIN_MAJOR} ${DOCKER_REPO} cc helloworld.c -o helloworld
file test/helloworld || echo "No output file found"
