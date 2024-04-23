#! /usr/bin/env bash

main() {

# This script has been generated automatically by Hydra from the build
# at https://hydra.nixos.org/build/257139284.

set -e

tmpDir=${TMPDIR:-/tmp}/build-257139284
declare -a args extraArgs


info() {
    echo "[1;32m$1[0m" >&2
}


# Process the command line.
fetchOnly=
printFlags=
while [ $# -gt 0 ]; do
    arg="$1"
    shift
    if [ "$arg" = --help ]; then
        cat <<EOF
Usage: $0 [--dir PATH] [--run-env]

This script will reproduce Hydra build 257139284 of job nixos:release-23.11:
(available at https://hydra.nixos.org/build/257139284).  It will fetch
all inputs of the Hydra build, then invoke Nix to build the job and
all its dependencies.

The inputs will be stored in $tmpDir.  This can be overriden using the
--dir flag.  After the build, the result of the build is available via
the symlink $tmpDir/result.

Flags:

  --dir PATH
    Override the location where the inputs and result symlink are stored.

  --run-env
    Fetch the inputs and build the dependencies, then start an
    interactive shell in which the environment is equal to that used
    to perform the build.  See the description of the --run-env flag
    in the nix-build(1) manpage for more details.

  --fetch
    Fetch the inputs and then exit.

  --print-flags
    Fetch the inputs, then print the argument to nix-build on stdout
    and exit.

Any additional flags are passed to nix-build.  See the nix-build(1)
manpage for details.
EOF
        exit 0
    elif [ "$arg" = --dir ]; then
        tmpDir="$1"
        if [ -z "$tmpDir" ]; then
            echo "$0: --dir requires an argument" >&2
            exit 1
        fi
        shift
    elif [ "$arg" = --fetch ]; then
        fetchOnly=1
    elif [ "$arg" = --print-flags ]; then
        printFlags=1
    else
        extraArgs+=("$arg")
    fi
done


mkdir -p "$tmpDir"
cd "$tmpDir"
info "storing inputs and results in $tmpDir..."


requireCommand() {
    local cmd="$1"
    if ! type -P "$cmd" > /dev/null; then
        echo "$0: command ‘$cmd’ is not installed; please install it and try again" >&2
        exit 1
    fi
    return 0
}


# Fetch the inputs.

inputDir=


inputDir="$tmpDir/nixpkgs/source"

if ! [ -d "$inputDir" ]; then
    info "fetching Git input ‘nixpkgs’ from ‘https://github.com/NixOS/nixpkgs.git’ (commit a5e4bbcb4780c63c79c87d29ea409abf097de3f7)..."
    requireCommand git
    inputDirTmp="$inputDir.tmp"
    rm -rf "$inputDirTmp"
    mkdir -p "$inputDirTmp"
    git clone 'https://github.com/NixOS/nixpkgs.git' "$inputDirTmp"
    (cd "$inputDirTmp" && git checkout 'a5e4bbcb4780c63c79c87d29ea409abf097de3f7')
    revCount="$(cd "$inputDirTmp" && (git rev-list 'a5e4bbcb4780c63c79c87d29ea409abf097de3f7' | wc -l))"
    rm -rf "$inputDirTmp/.git"
    mv "$inputDirTmp" "$inputDir"
    echo -n $revCount > "$tmpDir/nixpkgs/rev-count"
else
    revCount="$(cat "$tmpDir/nixpkgs/rev-count")"
fi

args+=(--arg 'nixpkgs' "{ outPath = $inputDir; rev = \"a5e4bbcb4780c63c79c87d29ea409abf097de3f7\"; shortRev = \"a5e4bbc\"; revCount = $revCount; }")


nixExprInputDir="$inputDir"

if [ -n "$inputDir" ]; then
    args+=(-I nixpkgs=$inputDir)
fi

inputDir=

args+=(--arg 'stableBranch' 'true')

if [ -n "$inputDir" ]; then
    args+=(-I stableBranch=$inputDir)
fi

inputDir=

args+=(--arg 'supportedSystems' '[ "x86_64-linux" "aarch64-linux" ]') # FIXME: escape

if [ -n "$inputDir" ]; then
    args+=(-I supportedSystems=$inputDir)
fi


if [ -n "$fetchOnly" ]; then exit 0; fi


# Run nix-build.

requireCommand nix-build

if [ -z "$nixExprInputDir" ]; then
    echo "$0: don't know the path to the Nix expression!" >&2
    exit 1
fi

args+=(--option extra-binary-caches 'https://hydra.nixos.org/')

# Since Hydra runs on x86_64-linux, pretend we're one.  This matters
# when evaluating jobs that rely on builtins.currentSystem.
args+=(--option system x86_64-linux)

args+=("$nixExprInputDir/nixos/release-combined.nix" -A '')

if [ -n "$printFlags" ]; then
    first=1
    for i in "${args[@]}"; do
        if [ -z "$first" ]; then printf " "; fi
        first=
        printf "%q" "$i"
    done
    exit 0
fi

info "running nix-build..."
echo "using the following invocation:" >&2
set -x
nix-build "${args[@]}" "${extraArgs[@]}"
}

main "$@"
