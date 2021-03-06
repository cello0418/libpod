#!/bin/bash

# This script is called by packer on the subject Ubuntu VM, to setup the podman
# build/test environment.  It's not intended to be used outside of this context.

set -e

# Load in library (copied by packer, before this script was run)
source /tmp/libpod/$SCRIPT_BASE/lib.sh

req_env_var "
SCRIPT_BASE $SCRIPT_BASE
CNI_COMMIT $CNI_COMMIT
CRIO_COMMIT $CRIO_COMMIT
RUNC_COMMIT $RUNC_COMMIT
"

install_ooe

export GOPATH="$(mktemp -d)"
trap "sudo rm -rf $GOPATH" EXIT

ooe.sh sudo apt-get -qq update
ooe.sh sudo apt-get -qq update  # sometimes it needs to get it twice :S
ooe.sh sudo apt-get -qq upgrade
ooe.sh sudo apt-get -qq install --no-install-recommends \
    apparmor \
    autoconf \
    automake \
    bison \
    btrfs-tools \
    build-essential \
    curl \
    e2fslibs-dev \
    gawk \
    gettext \
    golang \
    go-md2man \
    iptables \
    libaio-dev \
    libapparmor-dev \
    libcap-dev \
    libdevmapper-dev \
    libdevmapper1.02.1 \
    libfuse-dev \
    libglib2.0-dev \
    libgpgme11-dev \
    liblzma-dev \
    libostree-dev \
    libprotobuf-c0-dev \
    libprotobuf-dev \
    libtool \
    libtool \
    libudev-dev \
    lsof \
    netcat \
    pkg-config \
    protobuf-c-compiler \
    protobuf-compiler \
    python-minimal \
    python3-dateutil \
    python3-pip \
    python3-psutil \
    python3-pytoml \
    python3-setuptools \
    socat \
    unzip \
    xz-utils

echo "Fixing Ubuntu kernel not enabling swap accounting by default"
SEDCMD='s/^GRUB_CMDLINE_LINUX="(.*)"/GRUB_CMDLINE_LINUX="\1 cgroup_enable=memory swapaccount=1"/g'
ooe.sh sudo sed -re "$SEDCMD" -i /etc/default/grub.d/*
ooe.sh sudo sed -re "$SEDCMD" -i /etc/default/grub
ooe.sh sudo update-grub

install_runc

install_conmon

install_cni_plugins

install_buildah

install_packer_copied_files

install_varlink

sudo curl https://raw.githubusercontent.com/projectatomic/registries/master/registries.fedora\
          -o /etc/containers/registries.conf

ubuntu_finalize

echo "SUCCESS!"
