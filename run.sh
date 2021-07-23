#!/bin/sh


# What is a best one? set -eux?
set -x

podman \
build \
--file Containerfile \
--tag test-nix-installer

podman images