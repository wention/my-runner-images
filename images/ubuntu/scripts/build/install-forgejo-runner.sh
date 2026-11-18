#!/bin/bash -e
################################################################################
##  File:  install-forgejo-runner.sh
##  Desc:  Install Forgejo Runner
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Install Forgejo Runner
download_url="https://code.forgejo.org/forgejo/runner/releases/download/v13.2.1/forgejo-runner-13.2.1-linux-amd64.xz"
archive_path=$(download_with_retry "$download_url")
xz -dc "$archive_path" > "/usr/local/bin/forgejo-runner"
chmod +x /usr/local/bin/forgejo-runner
