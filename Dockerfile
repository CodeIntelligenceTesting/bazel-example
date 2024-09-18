FROM ubuntu:22.04

WORKDIR /work

# curl needed to download cifuzz and bazelisk
# git needed by bazel to clone external repositories
# python3 needed by rules_fuzzing to prepare the corpus direcotry
# lcov needed by cifuzz to parse coverage reports
RUN apt update && apt install -y curl git python3 lcov

# Install bazelisk
RUN curl https://github.com/bazelbuild/bazelisk/releases/download/v1.21.0/bazelisk-linux-amd64 -L -o /usr/bin/bazel && chmod +x /usr/bin/bazel

# Install latest version of cifuzz
ARG CIFUZZ_DOWNLOAD_TOKEN
RUN sh -c "$(curl -fsSL https://downloads.code-intelligence.com/assets/install-cifuzz.sh)" $CIFUZZ_DOWNLOAD_TOKEN && rm cifuzz_installer

# Copy example project
COPY . .

# Build the project to populate the bazel cache
# Warning: This will take some time and produce a large docker image.
RUN bazel build //...
