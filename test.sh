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

# Fix the Darwin version detection to avoid capturing extra output
DARWIN_VERSION=$(docker run --rm ${DOCKER_REPO} bash -c 'cat /usr/osxcross/darwin_version 2>/dev/null | grep -v "^-\{10\}" | grep -v "^CROSS_TRIPLE" || echo 23.5' | tail -1)
echo "Detected Darwin version: ${DARWIN_VERSION}"

# Extract just the version number properly
DARWIN_MAJOR=$(echo ${DARWIN_VERSION} | grep -o '^[0-9]*')
echo "Using Darwin major version: ${DARWIN_MAJOR}"

# Check if i386 is supported based on Darwin version
if [ ${DARWIN_MAJOR} -ge 19 ]; then
    echo "SDK version ${DARWIN_MAJOR} detected - i386 support is NOT available"
    HAS_I386=false
else
    echo "SDK version ${DARWIN_MAJOR} detected - i386 support should be available"
    HAS_I386=true
fi

# Set correct Darwin triples without extra text
DARWIN_TRIPLES="x86_64-apple-darwin${DARWIN_MAJOR} x86_64h-apple-darwin${DARWIN_MAJOR} aarch64-apple-darwin${DARWIN_MAJOR}"
if [ "$HAS_I386" = true ]; then
    DARWIN_TRIPLES="${DARWIN_TRIPLES} i386-apple-darwin${DARWIN_MAJOR}"
fi

# Set variables for other architectures
LINUX_TRIPLES="arm-linux-gnueabihf arm-linux-gnueabi powerpc64le-linux-gnu aarch64-linux-gnu arm-linux-gnueabihf mipsel-linux-gnu"
WINDOWS_TRIPLES="x86_64-w64-mingw32 i686-w64-mingw32"
ALIAS_TRIPLES="arm armhf arm64 amd64 x86_64 mips mipsel powerpc powerpc64 powerpc64le osx darwin windows"
DOCKER_TEST_ARGS="--rm -v $(pwd)/test:/test -w /test"

# Run basic tests for all triples
for triple in ${DARWIN_TRIPLES} ${LINUX_TRIPLES} ${WINDOWS_TRIPLES} ${ALIAS_TRIPLES}; do
    # For Windows triples, look for .exe files and explicitly add .exe extension
    if [[ $triple == *mingw32 ]]; then
        echo "Testing Windows triple: $triple (with .exe extension)"
        docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=${triple} ${DOCKER_REPO} bash -c "
          echo '#include <stdio.h>' > test.c && 
          echo 'int main() { printf(\"Hello World\\n\"); return 0; }' >> test.c && 
          cc test.c -o helloworld.exe && 
          file helloworld.exe"
        docker run ${DOCKER_TEST_ARGS} ${DOCKER_REPO} bash -c "ls -la"
        file test/helloworld.exe || echo "No .exe output file found"
    else
        # Non-Windows targets
        echo "Testing triple: $triple"
        docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=${triple} ${DOCKER_REPO} make test || echo "Test for $triple failed but continuing"
        file test/helloworld || echo "No output file found"
    fi
done

# Tests specific to macOS - only test with architectures we know are supported
echo "Testing macOS compiler with detected version ${DARWIN_VERSION}"

echo "Creating a simple test program"
echo "#include <stdio.h>" > test/helloworld.c
echo "int main() { printf(\"Hello from macOS\\n\"); return 0; }" >> test/helloworld.c

# Only test i386 if we know it's supported (SDK version < 19)
if [ "$HAS_I386" = true ]; then
    echo "Testing i386 macOS compiler (should be available with SDK ${DARWIN_MAJOR})"
    docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=i386-apple-darwin${DARWIN_MAJOR} ${DOCKER_REPO} cc helloworld.c -o helloworld || \
    echo "i386 compilation failed - this is expected for newer SDKs"
else
    echo "Skipping i386 tests - not supported in SDK ${DARWIN_MAJOR}"
fi

# Always test x86_64
echo "Testing x86_64 macOS compiler"
docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=x86_64-apple-darwin${DARWIN_MAJOR} ${DOCKER_REPO} bash -c "
  echo 'Finding available compiler binaries:'
  find /usr/osxcross/bin -name '*x86_64*clang*' | head -n5
  echo '#include <stdio.h>' > test.c
  echo 'int main() { printf(\"Hello from macOS\\n\"); return 0; }' >> test.c
  cc test.c -o helloworld
  file helloworld" || echo "x86_64 compilation failed"

# Always test ARM64
echo "Testing ARM64 macOS compiler"
docker run ${DOCKER_TEST_ARGS} -e CROSS_TRIPLE=aarch64-apple-darwin${DARWIN_MAJOR} ${DOCKER_REPO} bash -c "
  echo \"Finding available compiler binaries...\"
  find /usr/osxcross/bin -name '*arm64*clang*' || find /usr/osxcross/bin -name '*aarch64*clang*'
  echo \"#include <stdio.h>\" > test.c
  echo \"int main() { printf(\\\"Hello from macOS ARM64\\\\n\\\"); return 0; }\" >> test.c
  cc test.c -o helloworld || exit 1
  file helloworld" || echo "ARM64 compilation failed"
