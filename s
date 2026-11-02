#!/bin/sh

export PACKER_LOG=1
# packer build -on-error=ask ubuntu-qemu.pkr.hcl

packer build ubuntu-qemu.pkr.hcl
