

## With local git clone


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

```bash
nix flake metadata '.#'
```

```bash
nix --cores 8 flake check --verbose '.#' \
&& nix --cores 8 build --no-link --print-out-paths '.#myappAarch64Linux' \
&& nix --cores 8 build --no-link --print-out-paths '.#testBinfmtRiscv64'
```
