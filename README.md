# crossbuild
:earth_africa: multiarch cross compiling environments

[![actions](https://github.com/startergo/crossbuild/actions/workflows/actions.yml/badge.svg)](https://github.com/startergo/crossbuild/actions/workflows/actions.yml)

![](https://raw.githubusercontent.com/multiarch/dockerfile/master/logo.jpg)

This is a multiarch Docker build environment image.
You can use this image to produce binaries for multiple architectures.

## Supported targets

Triple                 | Aliases                               | linux | osx | windows
-----------------------|---------------------------------------|-------|-----|--------
x86_64-linux-gnu       | **(default)**, linux, amd64, x86_64   |   X   |     |
arm-linux-gnueabi      | arm, armv5                            |   X   |     |
arm-linux-gnueabihf    | armhf, armv7, armv7l                  |   X   |     |
aarch64-linux-gnu      | arm64, aarch64                        |   X   |     |
mipsel-linux-gnu       | mips, mipsel                          |   X   |     |
powerpc64le-linux-gnu  | powerpc, powerpc64, powerpc64le       |   X   |     |
x86_64-apple-darwin    | osx, osx64, darwin, darwin64          |       |  X  |
x86_64h-apple-darwin   | osx64h, darwin64h, x86_64h            |       |  X  |
i386-apple-darwin¹     | osx32, darwin32                       |       |  X  |
aarch64-apple-darwin   | arm64-apple-darwin, osx-arm64, darwin-arm64 |   |  X  |
x86_64-w64-mingw32     | windows, win64                        |       |     |   X
i686-w64-mingw32       | win32                                 |       |     |   X

¹ *i386-apple-darwin requires building with SDK < 10.15 (Darwin 19). The default build uses SDK 14.5 (Darwin 23), which does not support 32-bit targets.*

## macOS SDK Variants

This image supports different macOS SDK versions through build arguments. The SDK version and Darwin version must match according to the macOS release:

| macOS Version | SDK Version | Darwin Version | i386 Support |
|---------------|-------------|----------------|--------------|
| Sonoma        | 14.x        | 23             | No           |
| Ventura       | 13.x        | 22             | No           |
| Monterey      | 12.x        | 21             | No           |
| Big Sur       | 11.x        | 20             | No           |
| Catalina      | 10.15       | 19             | No           |
| Mojave        | 10.14       | 18             | Yes          |
| High Sierra   | 10.13       | 17             | Yes          |
| Sierra        | 10.12       | 16             | Yes          |
| Mavericks     | 10.9        | 13             | Yes          |

Available macOS SDK versions can be found at: https://github.com/joseluisq/macosx-sdks/blob/master/macosx_sdks.json

## Building the Image

The Docker image can be built with different macOS SDK versions and other parameters by using build arguments:

```console
# Default build (SDK 14.5/Darwin 23)
$ docker build -t startergo/crossbuild .

# Build with macOS SDK 13.4
$ docker build \
    --build-arg darwin_sdk_version=13.4 \
    --build-arg darwin_sdk_url=https://github.com/joseluisq/macosx-sdks/releases/download/13.4/MacOSX13.4.sdk.tar.xz \
    --build-arg darwin_version=22 \
    -t startergo/crossbuild:sdk-13.4 .

# Build with macOS SDK 10.13 for i386 support
$ docker build \
    --build-arg darwin_sdk_version=10.13 \
    --build-arg darwin_sdk_url=https://github.com/joseluisq/macosx-sdks/releases/download/10.13/MacOSX10.13.sdk.tar.xz \
    --build-arg darwin_version=17 \
    -t startergo/crossbuild:i386-support .

# Build with different minimum macOS version
$ docker build \
    --build-arg darwin_osx_version_min=11.0 \
    -t startergo/crossbuild:min-11.0 .

# Build with a specific osxcross revision
$ docker build \
    --build-arg osxcross_revision=542acc2ef6c21aeb3f109c03748b1015a71fed63 \
    -t startergo/crossbuild:osxcross-stable .

# Build with a combination of parameters
$ docker build \
    --build-arg darwin_sdk_version=12.0 \
    --build-arg darwin_osx_version_min=10.9 \
    --build-arg darwin_version=21 \
    --build-arg darwin_sdk_url=https://github.com/joseluisq/macosx-sdks/releases/download/12.0/MacOSX12.0.sdk.tar.xz \
    -t startergo/crossbuild:monterey-min10.9 .

# Build with macOS SDK 10.9 (Mavericks)
$ docker build \
    --build-arg darwin_sdk_version=10.9 \
    --build-arg darwin_sdk_url=https://github.com/joseluisq/macosx-sdks/releases/download/10.9/MacOSX10.9.sdk.tar.xz \
    --build-arg darwin_version=13 \
    -t startergo/crossbuild:mavericks .
```

## Using crossbuild

#### x86_64

```console
$ docker run --rm -v $(pwd):/workdir startergo/crossbuild make helloworld
cc helloworld.c -o helloworld
$ file helloworld
helloworld: ELF 64-bit LSB  executable, x86-64, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.32, BuildID[sha1]=9cfb3d5b46cba98c5aa99db67398afbebb270cb9, not stripped
```

Misc: using `cc` instead of `make`

```console
$ docker run --rm -v $(pwd):/workdir startergo/crossbuild cc test/helloworld.c
```

#### arm

```console
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=arm-linux-gnueabi startergo/crossbuild make helloworld
cc     helloworld.c   -o helloworld
$ file helloworld
helloworld: ELF 32-bit LSB  executable, ARM, EABI5 version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.32, BuildID[sha1]=c8667acaa127072e05ddb9f67a5e48a337c80bc9, not stripped
```

#### armhf

```console
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=arm-linux-gnueabihf startergo/crossbuild make helloworld
cc     helloworld.c   -o helloworld
$ file helloworld
helloworld: ELF 32-bit LSB  executable, ARM, EABI5 version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.32, BuildID[sha1]=ad507da0b9aeb78e7b824692d4bae6b2e6084598, not stripped
```

#### powerpc 64-bit el

```console
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=powerpc64le-linux-gnu startergo/crossbuild make helloworld
cc     helloworld.c   -o helloworld
$ file helloworld
helloworld: ELF 64-bit LSB  executable, 64-bit PowerPC or cisco 7500, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.32, BuildID[sha1]=035c50a8b410361d3069f77e2ec2454c70a140e8, not st
ripped
```

#### arm64

```console
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=aarch64-linux-gnu startergo/crossbuild make helloworld
cc     helloworld.c   -o helloworld
$ file helloworld
helloworld: ELF 64-bit LSB  executable, ARM aarch64, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 3.7.0, BuildID[sha1]=dce6100f0bc19504bc19987535f3cc04bd550d60, not stripped
```

#### mips el

```console
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=mipsel-linux-gnu startergo/crossbuild make helloworld
cc     helloworld.c   -o helloworld
$ file helloworld
helloworld: ELF 32-bit LSB  executable, MIPS, MIPS-II version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.32, BuildID[sha1]=d6b2f608a3c1a56b8b990be66eed0c41baaf97cd, not stripped
```

### darwin i386

> **Note**: This example requires a container built using an SDK version 10.14 (Darwin 18) or earlier.

```console
# Build the container with i386 support
$ docker build \
  --build-arg darwin_sdk_version=10.13 \
  --build-arg darwin_sdk_url=https://github.com/joseluisq/macosx-sdks/releases/download/10.13/MacOSX10.13.sdk.tar.xz \
  --build-arg darwin_version=17 \
  -t startergo/crossbuild:i386-support .

# Then use it for i386 compilation
$ docker run -it --rm -v $(pwd):/workdir -e CROSS_TRIPLE=i386-apple-darwin17 startergo/crossbuild:i386-support make helloworld
o32-clang     helloworld.c   -o helloworld
$ file helloworld
helloworld: Mach-O executable i386
```

#### darwin x86_64

```console
$ docker run -it --rm -v $(pwd):/workdir -e CROSS_TRIPLE=x86_64-apple-darwin23 startergo/crossbuild make helloworld
o64-clang     helloworld.c   -o helloworld
$ file helloworld
helloworld: Mach-O 64-bit executable x86_64
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=osx64 startergo/crossbuild make helloworld
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=darwin64 startergo/crossbuild make helloworld
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=x86_64-apple-darwin startergo/crossbuild make helloworld
```

#### darwin arm64 (Apple Silicon)

```console
$ docker run -it --rm -v $(pwd):/workdir -e CROSS_TRIPLE=aarch64-apple-darwin23 startergo/crossbuild make helloworld
cc     helloworld.c   -o helloworld
$ file helloworld
helloworld: Mach-O 64-bit executable arm64
```

# These all resolve to aarch64-apple-darwin23
```console
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=arm64-apple-darwin23 startergo/crossbuild make helloworld
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=osx-arm64 startergo/crossbuild make helloworld
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=darwin-arm64 startergo/crossbuild make helloworld
```

#### windows i386

```console
$ docker run -it --rm -v $(pwd):/workdir -e CROSS_TRIPLE=i686-w64-mingw32 startergo/crossbuild make helloworld
o32-clang     helloworld.c   -o helloworld
$ file helloworld
helloworld: PE32 executable (console) Intel 80386, for MS Windows
```

#### windows x86_64

```console
$ docker run -it --rm -v $(pwd):/workdir -e CROSS_TRIPLE=x86_64-w64-mingw32 startergo/crossbuild make helloworld
o64-clang     helloworld.c   -o helloworld
$ file helloworld
helloworld: PE32+ executable (console) x86-64, for MS Windows
```

# SDK Version Note

This image now uses macOS SDK 14.5 by default, with corresponding Darwin version 23.5. When using the macOS cross-compiler, use one of these approaches:

```console
# For x86_64 (Intel Macs)
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=x86_64-apple-darwin23 startergo/crossbuild make helloworld

# For ARM64/Apple Silicon Macs
$ docker run --rm -v $(pwd):/workdir -e CROSS_TRIPLE=aarch64-apple-darwin23 startergo/crossbuild make helloworld
```

## Using crossbuild in a Dockerfile

```Dockerfile
FROM startergo/crossbuild
RUN git clone https://github.com/bit-spark/objective-c-hello-world
ENV CROSS_TRIPLE=x86_64-apple-darwin
WORKDIR /workdir/objective-c-hello-world
RUN crossbuild ./compile-all.sh
```

## Projects using **crossbuild**

* [scaleway/initrd](https://github.com/scaleway/initrd)
* [multiarch/build-xnbd-client-static](https://github.com/multiarch/build-xnbd-client-static/)
* [tencherry10/til](https://github.com/tencherry10/til)

## Credit

This project is inspired by the [cross-compiler](https://github.com/steeve/cross-compiler) by the venerable [Steeve Morin](https://github.com/steeve)

## Legal note

OSX/Darwin/Apple builds: 
**[Please ensure you have read and understood the Xcode license
   terms before continuing.](https://www.apple.com/legal/sla/docs/xcode.pdf)**


## License

MIT
