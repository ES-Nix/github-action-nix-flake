FROM ubuntu:21.04 AS base-ubuntu

RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y \
    ca-certificates \
    curl \
    sudo \
    tar \
    xz-utils \
 && apt-get -y autoremove \
 && apt-get -y clean  \
 && rm -rf /var/lib/apt/lists/*

RUN addgroup nixgroup \
 && adduser \
    --quiet \
    --disabled-password \
    --shell /bin/bash \
    --home /home/nixuser \
    --gecos "User" nixuser \
    --ingroup nixgroup \
 && usermod -a -G sudo nixuser \
 && echo "nixuser:123" | chpasswd \
 && echo 'nixuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
 && mkdir -p /home/nixuser/tmp \
 && chown -R nixuser: /home/nixuser/tmp

USER nixuser

ENV USER nixuser



# FROM base-ubuntu AS test-in-ubuntu
#
# RUN test -d /nix || sudo mkdir --mode=0755 /nix \
# && sudo chown "$USER": /nix \
# && SHA256=7c60027233ae556d73592d97c074bc4f3fea451d \
# && curl -fsSL https://raw.githubusercontent.com/ES-Nix/get-nix/"$SHA256"/get-nix.sh | sh \
# && . "$HOME"/.nix-profile/etc/profile.d/nix.sh \
# && . ~/."$(ps -ocomm= -q $$)"rc \
# && export TMPDIR=/tmp \
# && export OLD_NIX_PATH="$(readlink -f $(which nix-env))" \
# && nix-shell -I nixpkgs=channel:nixos-21.05 --keep OLD_NIX_PATH --packages nixFlakes --run 'nix-env --uninstall $OLD_NIX_PATH && nix-collect-garbage --delete-old && nix profile install nixpkgs#nixFlakes' \
# && sudo rm -fv /nix/store/*-nix-2.3.1*/bin/nix \
# && unset OLD_NIX_PATH \
# && nix-collect-garbage --delete-old \
# && nix store gc \
# && nix flake --version


# TODO:
# RUN addgroup app_group \
#  && adduser \
#     --quiet \
#     --disabled-password \
#     --shell /bin/bash \
#     --home /home/app_user \
#     --gecos "User" app_user \
#     --ingroup app_group
#
# RUN chmod 0700 /home/app_user \
#  && chown --recursive app_user:app_group /home/app_user
#
# RUN addgroup bar \
#  && adduser \
#     --quiet \
#     --disabled-password \
#     --shell /bin/bash \
#     --home /home/foo \
#     --gecos "User" foo \
#     --ingroup bar
#
# RUN chmod 0700 /home/foo \
#  && chown --recursive foo:bar /home/foo
