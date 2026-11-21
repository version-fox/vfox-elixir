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

# The development container: the Go toolchain the E2E suite and the Go checks
# use, the Lua tools, vfox and the license tool, at the versions pinned in
# .github/workflows. The E2E suite runs on this Linux userland directly, the
# way CI runs it on the Ubuntu runners; see docs/e2e.md.

FROM golang:1.27.1

# Erlang/OTP is compiled from source by the E2E suite, so these are its build
# dependencies. The base image is Debian, which ships JDK 17 rather than the
# JDK 11 of the Ubuntu runners; jinterface only needs a javac, so either builds.
RUN <<EOF
set -o errexit -o nounset -o xtrace
apt-get update
apt-get install --assume-yes --no-install-recommends \
    autoconf \
    build-essential \
    ca-certificates \
    curl \
    fop \
    git \
    libncurses-dev \
    libssh-dev \
    libssl-dev \
    libxml2-utils \
    m4 \
    openjdk-17-jdk-headless \
    unixodbc-dev \
    unzip \
    xsltproc \
    zip
rm --recursive --force /var/lib/apt/lists/*
EOF

# Keep the tool versions below in step with .github/workflows/lint.yml (stylua,
# lua-language-server), test.yml and e2e.yml (vfox), and license.yml (license-eye).
ARG STYLUA_VERSION=2.5.2
ARG LUA_LANGUAGE_SERVER_VERSION=3.19.1
ARG VFOX_VERSION=1.1.0
ARG VFOX_SHA256_X86_64=3b33c3c468b27bc17aecf0d6d3af24fe49fe204972984904a136a47b402a0ee4
ARG VFOX_SHA256_AARCH64=e702e057dfe588200727dfb3cf786d181b13f015cbcc9e13679a3edcfd07e430

RUN <<EOF
set -o errexit -o nounset -o xtrace
case "$(dpkg --print-architecture)" in
    amd64)
        stylua_asset=stylua-linux-x86_64.zip
        luals_asset="lua-language-server-${LUA_LANGUAGE_SERVER_VERSION}-linux-x64.tar.gz"
        vfox_arch=x86_64
        vfox_sha256="${VFOX_SHA256_X86_64}"
        ;;
    arm64)
        stylua_asset=stylua-linux-aarch64.zip
        luals_asset="lua-language-server-${LUA_LANGUAGE_SERVER_VERSION}-linux-arm64.tar.gz"
        vfox_arch=aarch64
        vfox_sha256="${VFOX_SHA256_AARCH64}"
        ;;
    *) echo "FAIL unsupported architecture $(dpkg --print-architecture)" >&2; exit 1 ;;
esac
curl --fail --silent --show-error --location --output /tmp/stylua.zip \
    "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/${stylua_asset}"
unzip -q /tmp/stylua.zip -d /usr/local/bin
rm --force /tmp/stylua.zip
curl --fail --silent --show-error --location --output /tmp/luals.tar.gz \
    "https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LANGUAGE_SERVER_VERSION}/${luals_asset}"
mkdir --parents /opt/lua-language-server
tar --extract --gzip --file /tmp/luals.tar.gz --directory /opt/lua-language-server
rm --force /tmp/luals.tar.gz
ln --symbolic /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
curl --fail --silent --show-error --location --output /tmp/vfox.tar.gz \
    "https://github.com/version-fox/vfox/releases/download/v${VFOX_VERSION}/vfox_${VFOX_VERSION}_linux_${vfox_arch}.tar.gz"
echo "${vfox_sha256}  /tmp/vfox.tar.gz" | sha256sum --check
tar --extract --gzip --file /tmp/vfox.tar.gz --directory /usr/local/bin --strip-components=1 \
    "vfox_${VFOX_VERSION}_linux_${vfox_arch}/vfox"
rm --force /tmp/vfox.tar.gz
stylua --version
lua-language-server --version
vfox --version
EOF

# The license tool at the version pinned in .github/workflows/license.yml.
RUN GOBIN=/usr/local/bin go install github.com/apache/skywalking-eyes/cmd/license-eye@v0.9.0 \
    && command -v license-eye
