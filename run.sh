#!/bin/sh


podman \
build \
--file ../../Containerfile \
--tag test-nix-installer

podman images