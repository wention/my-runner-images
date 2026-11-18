#!/bin/bash -e
################################################################################
##  File:  configure-apt-sources.sh
##  Desc:  Configure apt sources with failover mirror based on cloud environment.
################################################################################

source $HELPER_SCRIPTS/os.sh

if is_ubuntu20 || is_ubuntu22; then
    sources_file="/etc/apt/sources.list"
else
    sources_file="/etc/apt/sources.list.d/ubuntu.sources"
fi

touch /etc/apt/apt-mirrors.txt


printf "http://10.1.1.12:30080/debian/ubuntu/\tpriority:1\n" | tee -a /etc/apt/apt-mirrors.txt
printf "http://mirrors.nju.edu.cn/ubuntu/\tpriority:2\n" | tee -a /etc/apt/apt-mirrors.txt
printf "http://mirrors.ustc.edu.cn/ubuntu/\tpriority:3\n" | tee -a /etc/apt/apt-mirrors.txt
printf "https://archive.ubuntu.com/ubuntu/\tpriority:4\n" | tee -a /etc/apt/apt-mirrors.txt
printf "https://security.ubuntu.com/ubuntu/\tpriority:5\n" | tee -a /etc/apt/apt-mirrors.txt

# Also match the base image defaults, in case cloud-init has not switched the sources to the Azure mirror.
# cloud-init's fallback mirrors have no trailing slash, so it is optional.
if is_ubuntu20 || is_ubuntu22; then
    sed -i -E 's#http://(archive|security)\.ubuntu\.com/ubuntu/?([[:space:]]|$)#mirror+file:/etc/apt/apt-mirrors.txt\2#' /etc/apt/sources.list

    # Apt changes to survive Cloud Init
    cp -f /etc/apt/sources.list /etc/cloud/templates/sources.list.ubuntu.tmpl
else
    sed -i -E 's#http://(archive|security)\.ubuntu\.com/ubuntu/?([[:space:]]|$)#mirror+file:/etc/apt/apt-mirrors.txt\2#' /etc/apt/sources.list.d/ubuntu.sources

    # Apt changes to survive Cloud Init
    cp -f /etc/apt/sources.list.d/ubuntu.sources /etc/cloud/templates/sources.list.ubuntu.deb822.tmpl
fi

# Configure APT snapshot if the timestamp is provided
if [[ -n "${APT_SNAPSHOT_TIMESTAMP:-}" ]]; then
    echo "APT::Snapshot \"${APT_SNAPSHOT_TIMESTAMP}\";" > /etc/apt/apt.conf.d/zz-snapshot
fi

echo "Configured APT repositories"
for repository_file in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
    [[ -f "$repository_file" ]] || continue
    echo "--- $repository_file"
    cat "$repository_file"
    apt-get update
done

echo "Configured APT mirrors"
cat /etc/apt/apt-mirrors.txt