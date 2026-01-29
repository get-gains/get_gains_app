# Dockerfile for Flutter Android builds using FVM
FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk-headless \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set up environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

# Install Android SDK
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip && \
    rm cmdline-tools.zip && \
    mv cmdline-tools latest

# Accept Android SDK licenses and install required components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Install FVM (requires Dart, which we'll get via Flutter)
# First, install Flutter standalone to get Dart
ENV FLUTTER_HOME=/opt/flutter
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 ${FLUTTER_HOME}
ENV PATH="${PATH}:${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin"

# Pre-cache Flutter and Dart SDK
RUN flutter precache --android

# Install FVM
RUN dart pub global activate fvm

# Add FVM to PATH
ENV PATH="${PATH}:/root/.pub-cache/bin"

# Set working directory
WORKDIR /app

# Copy FVM config first (for caching)
COPY .fvmrc ./

# Install Flutter via FVM (uses the version from .fvmrc)
RUN fvm install stable && fvm use stable --force

# Copy project files
COPY pubspec.yaml pubspec.lock ./
COPY android ./android/
COPY lib ./lib/
COPY . .

# Create placeholder .env file for CI builds (if not present)
RUN touch .env

# Get dependencies
RUN fvm flutter pub get

# Generate code (freezed, riverpod, drift, etc.)
RUN fvm flutter pub run build_runner build --delete-conflicting-outputs

# Default command: build Android APK
CMD ["fvm", "flutter", "build", "apk", "--debug"]
