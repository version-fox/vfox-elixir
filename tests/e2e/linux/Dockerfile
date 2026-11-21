# Copyright 2026 vfox-elixir contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The build context is tests/e2e/linux, not the repository root: the image
# holds the tools only. The plugin and the Go suite come from the read-only
# repository mount at run time (see docs/e2e.md).
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
# Elixir warns about a latin1 VM locale, and the CI runners use UTF-8.
ENV LANG=C.UTF-8

# Erlang/OTP is built from source by vfox-erlang: ./configure, make and
# make docs (chunks). The list follows the OTP 26 INSTALL requirements:
# a C toolchain, Perl 5, ncurses and OpenSSL headers, flex (megaco), and
# xsltproc with xmllint (documentation). wxWidgets, a JDK and fop are left out
# on purpose: configure skips the wx, jinterface and PDF applications without
# them, and the suite does not use them.
RUN set -o errexit -o nounset -o xtrace; \
    apt-get update; \
    apt-get install --assume-yes --no-install-recommends \
        autoconf \
        build-essential \
        ca-certificates \
        curl \
        flex \
        git \
        libncurses-dev \
        libssl-dev \
        libxml2-utils \
        m4 \
        perl \
        unixodbc-dev \
        unzip \
        xsltproc; \
    rm -rf /var/lib/apt/lists/*

# vfox 1.1.0 is the first release with the Detect hook (vfox link --detect).
# The archive must match the SHA-256 published for the release before it is
# unpacked.
ARG VFOX_VERSION=1.1.0
ARG VFOX_SHA256=3b33c3c468b27bc17aecf0d6d3af24fe49fe204972984904a136a47b402a0ee4
RUN set -o errexit -o nounset -o xtrace; \
    work="$(mktemp -d)"; \
    curl --fail --location --silent --show-error \
        --output "${work}/vfox.tar.gz" \
        "https://github.com/version-fox/vfox/releases/download/v${VFOX_VERSION}/vfox_${VFOX_VERSION}_linux_x86_64.tar.gz"; \
    echo "${VFOX_SHA256}  ${work}/vfox.tar.gz" | sha256sum --check --strict; \
    tar -xzf "${work}/vfox.tar.gz" -C "${work}"; \
    install -m 0755 "${work}/vfox_${VFOX_VERSION}_linux_x86_64/vfox" /usr/local/bin/vfox; \
    rm -rf "${work}"; \
    vfox --version

# The Go toolchain for the suite: the release go.mod names (go 1.27.1), taken
# from the official image so the container needs no toolchain download.
COPY --from=golang:1.27.1 /usr/local/go /usr/local/go

ENV PATH=/usr/local/go/bin:${PATH}
# The source tree is mounted read-only, so the build cache lives in /tmp.
ENV GOCACHE=/tmp/gocache
# Use only the toolchain above; never fetch another one.
ENV GOTOOLCHAIN=local
