# ================================
# Build image
# ================================
FROM swift:5.3-focal as build

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Build everything, with optimizations and test discovery
RUN swift build --enable-test-discovery -c release

# ================================
# Run image
# ================================
FROM swift:5.3-focal-slim

# Create a vapor user and group with /run as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /run vapor

# Switch to the new home directory
WORKDIR /run

# Copy built executable and any staged resources from builder
COPY --from=build --chown=vapor:vapor /build/.build/release /run

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Let Docker bind to port 8080
EXPOSE 8080

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
