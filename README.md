# GitHub Action nix flake


This is an example of how to build an not trivial nix flake in an GitHub Action.


Main source: 
- https://github.com/cachix/install-nix-action

Other references:
- https://github.com/NixOS/nix/pull/4224
- https://github.com/NixOS/nix/issues/4047


## Using the flake

So you dont need to have an local clone.

```bash
nix flake metadata 'github:ES-Nix/github-action-nix-flake/dev'
nix flake show 'github:ES-Nix/github-action-nix-flake/dev'

nix build --cores 8 --no-link --print-build-logs --print-out-paths 'github:ES-Nix/github-action-nix-flake/dev'

nix --cores 8 flake check --verbose 'github:ES-Nix/github-action-nix-flake/dev' \
&& nix --cores 8 build --no-link --print-out-paths 'github:ES-Nix/github-action-nix-flake/dev#testMyappOCIImage' \
&& nix --cores 8 build --no-link --print-out-paths 'github:ES-Nix/github-action-nix-flake/dev#myappAarch64Linux' \
&& nix --cores 8 build --no-link --print-out-paths 'github:ES-Nix/github-action-nix-flake/dev#testBinfmtRiscv64'
```


## With local git clone


Cloning using the Nix CLI:
```bash
nix flake clone 'git+ssh://git@github.com/ES-Nix/github-action-nix-flake.git' --dest github-action-nix-flake \
&& cd github-action-nix-flake 1>/dev/null 2>/dev/null \
&& git checkout dev \
&& (direnv --version 1>/dev/null 2>/dev/null && direnv allow) \
|| nix develop $SHELL
```

Cloning using the git CLI:
```bash
git clone git@github.com:ES-Nix/github-action-nix-flake.git \
&& cd github-action-nix-flake \
&& git checkout dev \
&& ((direnv 1>/dev/null 2>/dev/null && direnv allow) || nix develop .#)
```


```bash
nix flake metadata '.#'
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

nix --cores 8 flake check --verbose '.#' \
&& nix --cores 8 build --no-link --print-out-paths '.#testMyappOCIImage' \
&& nix --cores 8 build --no-link --print-out-paths '.#myappAarch64Linux' \
&& nix --cores 8 build --no-link --print-out-paths '.#testBinfmtRiscv64'
```


## In the VM

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose '.#automatic-vm'
```



Invoking in the host:
```bash
start
```


Or using with docker:
```bash
docker run -it --rm --publish=5000:5000 myapp-oci-image:0.0.1
```


Or using with podman:
```bash
podman run -it --rm --publish=5000:5000 localhost/myapp-oci-image:0.0.1
```


In other terminal:
```bash
curl http://127.0.0.1:5000
firefox http://127.0.0.1:5000
```

TODO: missing checks that validate code formating, like black.

```bash
python -m myapp?
python -c 'import myapp?'
```


## Updating

```bash
nix flake update '.#'
 ```

