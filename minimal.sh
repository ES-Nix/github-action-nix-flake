#! /usr/bin/env bash



mkdir -pv poetry2nix-basic \
&& cd $_ \
&& nix \
flake \
init \
--template \
github:ES-nix/es#poetry2nixBasic
# direnv allow || true
nix flake check '.#' --verbose

#EXPR_NIX='
#(
#  let
#    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/a5e4bbcb4780c63c79c87d29ea409abf097de3f7");
#    pkgs = import nixpkgs {};
#    iso = (import "${pkgs.path}/nixos/release-combined.nix" { nixpkgs = { revCount = (6510 + 551362); shortRev = "${nixpkgs.shortRev}"; rev = "${nixpkgs.rev}";}; stableBranch = true;}).nixos.iso_minimal.x86_64-linux;
#
#  in
#    iso
#)
#'
#
#nix \
#build \
#--impure \
#--print-build-logs \
#--print-out-paths \
#--expr \
#"$EXPR_NIX"
#
#EXPECTED_SHA256='8144d72323c03baefd83899fdeed03c1524afba1cf6f6aa0a1358d100895a919'
#ISO_PATTERN_NAME='/nix/store/l364jwr1f8v2xp03j5zvlrdhy4dqi39j-nixos-minimal-23.11.6510.a5e4bbc-x86_64-linux.iso/iso/nixos-minimal-23.11.6510.a5e4bbc-x86_64-linux.iso'
## sha256sum "${ISO_PATTERN_NAME}"
#echo "${EXPECTED_SHA256}"'  '"${ISO_PATTERN_NAME}" | sha256sum -c
#
#
#nix \
#build \
#--impure \
#--print-build-logs \
#--print-out-paths \
#--rebuild \
#--expr \
#"$EXPR_NIX"
#
#EXPECTED_SHA256='8144d72323c03baefd83899fdeed03c1524afba1cf6f6aa0a1358d100895a919'
#ISO_PATTERN_NAME='/nix/store/l364jwr1f8v2xp03j5zvlrdhy4dqi39j-nixos-minimal-23.11.6510.a5e4bbc-x86_64-linux.iso/iso/nixos-minimal-23.11.6510.a5e4bbc-x86_64-linux.iso'
## sha256sum "${ISO_PATTERN_NAME}"
#echo "${EXPECTED_SHA256}"'  '"${ISO_PATTERN_NAME}" | sha256sum -c
