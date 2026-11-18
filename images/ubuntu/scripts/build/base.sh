#!/bin/sh

# Setup apt mirror
sed -E -i 's@//(archive|security|ports).ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list
# for DEB8222 format
sed -E -i 's@//(archive|security|ports).ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources

# Layer: Core build tools (rarely change - every few months)
echo 'APT::Sandbox::User "root";' > /etc/apt/apt.conf.d/00docker-buildkit
echo 'Dpkg::Use-Pty "0";' >> /etc/apt/apt.conf.d/00docker-buildkit
apt-get -qq update

# Build tools and compression utilities (alphabetically sorted)
apt-get -qq install -y --no-install-recommends \
    apt-utils \
    build-essential \
    patchelf cmake ccache \
    curl \
    file \
    gzip \
    jq \
    libffi-dev \
    rsync \
    sudo \
    unzip \
    wget \
    zip

# Layer: System essentials with Python (required for package management)
apt-get -qq install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg \
    gpg \
    libcairo2 \
    libssl-dev \
    lsb-release \
    openssh-client \
    python3 \
    python3-pip \
    python3-apt \
    python3-setuptools \
    python3-venv

update-alternatives --install /usr/bin/python python /usr/bin/python3 100

# set python pypi mirror (system-wide, inherited by the runner user)
cat << EOF > /etc/pip.conf
[global]
index-url = https://mirrors.ustc.edu.cn/pypi/web/simple
EOF

# Layer: Docker installation
# Using docker.io package for consistent multi-architecture support
apt-get -qq install -y --no-install-recommends \
    docker-compose \
    docker.io \
    docker-cli

# set docker mirror
cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.sparkcr.cn",
    "https://hub.rat.dev",
    "https://docker-registry.nmqu.com",
    "https://docker.hlmirror.com"
  ]
}
EOF

## Layer: Node.js installation
apt-get -qq install -y --no-install-recommends \
    npm

# Layer: uv, Python tools, git-annex
# https://astral.sh/uv/install.sh
curl -LsSf https://mirrors.ustc.edu.cn/github-release/astral-sh/uv/LatestRelease/uv-installer.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh

# set uv mirror (system-wide: uv tool / uv run both read /etc/uv/uv.toml)
mkdir -p /etc/uv
cat << EOF > /etc/uv/uv.toml
[[index]]
url = "https://mirrors.ustc.edu.cn/pypi/simple"
default = true
EOF

# Put tool executables and environments in world-accessible locations instead of /root
export UV_TOOL_BIN_DIR=/usr/local/bin
export UV_TOOL_DIR=/opt/uv/tools
export UV_PYTHON_INSTALL_DIR=/opt/uv/python
mkdir -p -m 755 "$UV_TOOL_DIR" "$UV_PYTHON_INSTALL_DIR"

uv tool install conan
uv tool install prek
uv tool install ruff
uv tool install mypy
uv tool install pytest
uv tool install black
uv tool install isort
uv tool install hatch
uv tool install git-annex

# Make the tool environments readable/executable for the runner user
chmod -R a+rX /opt/uv

# Install Forgejo Runner
curl -LsSf "https://code.forgejo.org/forgejo/runner/releases/download/v13.2.1/forgejo-runner-13.2.1-linux-amd64.xz" \
    | xz -dc > /usr/local/bin/forgejo-runner
chmod +x /usr/local/bin/forgejo-runner

# Install Forgejo cli
curl -LsSf "https://codeberg.org/forgejo-contrib/forgejo-cli/releases/download/v0.7.0/forgejo-cli-x86_64-linux.tar.gz" \
    | tar -xzvf - -C /usr/local/bin

apt-get clean

# runner 用户需要向 toolcache 写入下载的工具
mkdir -p /opt/hostedtoolcache
chmod 777 /opt/hostedtoolcache

git --version && \
    (command -v docker >/dev/null 2>&1 && docker --version || echo "Docker not installed") && \
python --version && \
uv --version && \
    (command -v node >/dev/null 2>&1 && node --version || echo "Node.js not installed") && \
    (command -v npm >/dev/null 2>&1 && npm --version || echo "npm not installed") && \
test -f /etc/pip.conf && test -f /etc/uv/uv.toml && \
ruff --version
