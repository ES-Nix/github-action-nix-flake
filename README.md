# github-action-nix-flake

Tests with github action and `nix` + `flakes`


Main source: 
- https://github.com/cachix/install-nix-action

To read:
- https://github.com/NixOS/nix/pull/4224
- https://github.com/NixOS/nix/issues/4047


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
git clone git@github.com:ES-Nix/.github.git \
&& cd .github \
&& git checkout feature/dx-with-nix-and-home-manager \
&& ((direnv 1>/dev/null 2>/dev/null && direnv allow) || nix develop .#)
```


Nix solves a huge set of really painfull problems.

What is going to be your click moment is unkown.

Note: there are things (kubernetes, race conditions from C to 
systemd units or evem Celery) 
that are not Nix fault's that it is not like it you would like.


