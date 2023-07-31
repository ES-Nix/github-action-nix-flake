# github-action-nix-flake
Tests with github action and `nix` + `flakes`


Main source: https://github.com/cachix/install-nix-action

To read:
- https://github.com/NixOS/nix/pull/4224
- https://github.com/NixOS/nix/issues/4047


```bash
nix flake clone 'github:ES-Nix/github-action-nix-flake/dev' --dest github-action-nix-flake/actions \
&& cd github-action-nix-flake/actions 1>/dev/null 2>/dev/null \
&& (direnv --version 1>/dev/null 2>/dev/null && direnv allow) \
|| nix develop $SHELL
```

```bash
git clone git@github.com:ES-Nix/.github.git \
&& cd .github \
&& git checkout feature/dx-with-nix-and-home-manager \
&& ((direnv 1>/dev/null 2>/dev/null && direnv allow) || nix develop .#)
```
