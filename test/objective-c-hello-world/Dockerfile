FROM startergo/crossbuild:latest

# Clone the test repository
RUN git clone https://github.com/bit-spark/objective-c-hello-world

# Set the target triple to match what's available in your updated image
ENV CROSS_TRIPLE=x86_64-apple-darwin23

WORKDIR /workdir/objective-c-hello-world

# Add debugging to see what's happening during build
RUN ls -la /usr/bin/cross* && \
    echo "CROSS_TRIPLE is set to: $CROSS_TRIPLE" && \
    # Run the compilation script with debugging enabled
    crossbuild sh -x ./compile-all.sh

# Verify the outputs
RUN ls -la && \
    file *.out || echo "No .out files found" && \
    file *
