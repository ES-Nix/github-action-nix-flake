#! /usr/bin/env bash



#mkdir -pv ~/poetry2nix-basic \
#&& cd $_ \
#&& nix \
#flake \
#init \
#--template \
#github:ES-nix/es#poetry2nixBasic
## direnv allow || true
#nix flake check '.#' --verbose


nix build --print-build-logs --print-out-paths 'github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8#pkgsMusl.nodejs'

EXPR_NIX='
(
  (
    (
      builtins.getFlake "github:NixOS/nixpkgs/0938d73bb143f4ae037143572f11f4338c7b2d1c"
    ).lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
                    "${toString (builtins.getFlake "github:NixOS/nixpkgs/0938d73bb143f4ae037143572f11f4338c7b2d1c")}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                    {
                      # https://nixos.wiki/wiki/Creating_a_NixOS_live_CD#Building_faster
                      # isoImage.squashfsCompression = "gzip -Xcompression-level 1";

                      # compress 6x faster than default
                      # but iso is 15% bigger
                      # tradeoff acceptable because we do not want to distribute
                      # default is xz which is very slow
                      isoImage.squashfsCompression = "zstd -Xcompression-level 9";
                    }
                  ];
    }
  ).config.system.build.isoImage
)
'

nix \
build \
--print-build-logs \
--print-out-paths \
--expr \
"$EXPR_NIX"

EXPECTED_SHA512='ce09cd8b0a2e0d5f9da2f921314417bf3f3904c7f11a590e7fde56c84a9ebecc78ee31faa7660efae332d4f6cc2bef129b3d214f2a53c52d7457d2869e310ebb'
ISO_PATTERN_NAME='result/iso/nixos-22.11.20221217.0938d73-x86_64-linux.iso'
# sha512sum "${ISO_PATTERN_NAME}"
echo "${EXPECTED_SHA512}"'  '"${ISO_PATTERN_NAME}" | sha512sum -c


nix \
build \
--print-build-logs \
--print-out-paths \
--rebuild \
--expr \
"$EXPR_NIX"

EXPECTED_SHA512='ce09cd8b0a2e0d5f9da2f921314417bf3f3904c7f11a590e7fde56c84a9ebecc78ee31faa7660efae332d4f6cc2bef129b3d214f2a53c52d7457d2869e310ebb'
ISO_PATTERN_NAME='result/iso/nixos-22.11.20221217.0938d73-x86_64-linux.iso'
echo "${EXPECTED_SHA512}"'  '"${ISO_PATTERN_NAME}" | sha512sum -c


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
