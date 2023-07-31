{
  description = "This an 'nix flake' :)";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      name = "github-action-nix-flake";

      pkgsAllowUnfree = import nixpkgs {
        # inherit system;
        system = "x86_64-linux";
        config = { allowUnfree = true; };
      };

    in
    rec {

      nixosConfigurations.nixosBuildVMX86_64LinuxPodman =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config = { allowUnfree = true; };
          };
        in
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # system = "aarch64-linux";
          modules =
            let
              nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly";
            in
            [
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/build-vm.nix"
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-vm.nix"
              # "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-guest.nix"
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/installer/cd-dvd/channel.nix"

              ({
                # https://gist.github.com/andir/88458b13c26a04752854608aacb15c8f#file-configuration-nix-L11-L12
                boot.loader.grub.extraConfig = "serial --unit=0 --speed=115200 \n terminal_output serial console; terminal_input serial console";
                boot.kernelParams = [
                  "console=tty0"
                  "console=ttyS0,115200n8"
                  # Set sensible kernel parameters
                  # https://nixos.wiki/wiki/Bootloader
                  # https://git.redbrick.dcu.ie/m1cr0man/nix-configs-rb/commit/ddb4d96dacc52357e5eaec5870d9733a1ea63a5a?lang=pt-PT
                  "boot.shell_on_fail"
                  "panic=30"
                  "boot.panic_on_fail" # reboot the machine upon fatal boot issues
                  # TODO: test it
                  "intel_iommu=on"
                  "iommu=pt"

                  # https://discuss.linuxcontainers.org/t/podman-wont-run-containers-in-lxd-cgroup-controller-pids-unavailable/13049/2
                  # https://github.com/NixOS/nixpkgs/issues/73800#issuecomment-729206223
                  # https://github.com/canonical/microk8s/issues/1691#issuecomment-977543458
                  # https://github.com/grahamc/nixos-config/blob/35388280d3b06ada5882d37c5b4f6d3baa43da69/devices/petunia/configuration.nix#L36
                  # cgroup_no_v1=all
                  "swapaccount=0"
                  "systemd.unified_cgroup_hierarchy=0"
                  "group_enable=memory"
                ];

                boot.tmpOnTmpfs = false;
                # https://github.com/AtilaSaraiva/nix-dotfiles/blob/main/lib/modules/configHost/default.nix#L271-L273
                boot.tmpOnTmpfsSize = "100%";

                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;

                users.users.nixuser = {
                  isSystemUser = true;
                  password = "1";
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "podman"
                    "kvm"
                    "libvirtd"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    direnv
                    gitFull
                    xorg.xclock
                    file
                    btop
                    # pkgsCross.aarch64-multiplatform-musl.pkgsStatic.hello

                    # firefox
                    # vscode
                    # (python3.buildEnv.override
                    #   {
                    #     extraLibs = with python3Packages; [ scikitimage opencv2 numpy ];
                    #   }
                    # )
                  ];
                  shell = pkgs.bashInteractive;
                  uid = 1234;
                  autoSubUidGidRange = true;

                  openssh.authorizedKeys.keyFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];

                  openssh.authorizedKeys.keys = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly"
                  ];
                };

                systemd.services.adds-change-workdir = {
                  script = "echo cd /tmp/shared >> /home/nixuser/.profile";
                  wantedBy = [ "multi-user.target" ];
                };

                systemd.services.creates-if-not-exist = {
                  script = "echo touch /home/nixuser/.Xauthority >> /home/nixuser/.profile";
                  wantedBy = [ "multi-user.target" ];
                };

                # https://unix.stackexchange.com/questions/619671/declaring-a-sym-link-in-a-users-home-directory#comment1159159_619703
                systemd.services.populate-history = {
                  script = "echo \"ls -al /nix/store\" >> /home/nixuser/.bash_history";
                  wantedBy = [ "multi-user.target" ];
                };

                virtualisation = {
                  # following configuration is added only when building VM with build-vm
                  memorySize = 3072; # Use MiB memory.

                  # nixos-disk-image> ERROR: cptofs failed. diskSize might be too small for closure.
                  diskSize = 15*1024; # Use MiB memory.
                  cores = 7; # Simulate 3 cores.
                  #
                  podman.enable = true;

                  #
                  useNixStoreImage = true;
                  writableStore = true; # TODO

                  # https://github.com/nix-community/nixos-generators/blob/10079333313ff62446e6f2b0e7c5231c7431d269/formats/vm-nogui.nix#L17C1-L18
                  # graphics = false;
                  # qemu.options = [ "-serial mon:stdio -display none -monitor none" ];
                  qemu.options = [ "-display none -monitor none -daemonize" ];
                };
                security.polkit.enable = true;

                # https://nixos.wiki/wiki/Libvirt
                boot.extraModprobeConfig = "options kvm_intel nested=1";
                boot.kernelModules = [
                  "kvm-intel"
                  "vfio-pci"
                ];

                # hardware.opengl.enable = true;
                # hardware.opengl.driSupport = true;

                nixpkgs.config.allowUnfree = true;
                nix = {
                  package = pkgs.nix;
                  # package = pkgsCross.aarch64-multiplatform-musl.pkgsStatic.nix;
                  extraOptions = "experimental-features = nix-command flakes";
                  readOnlyStore = true;
                };

                boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

                # Enable the X11 windowing system.
                services.xserver = {
                  enable = true;
                  displayManager.gdm.enable = true;
                  displayManager.startx.enable = true;
                  logFile = "/var/log/X.0.log";
                  desktopManager.xterm.enable = true;
                  # displayManager.gdm.autoLogin.enable = true;
                  # displayManager.gdm.autoLogin.user = "nixuser";
                };
                services.spice-vdagentd.enable = true;

                # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
                services.openssh = {
                  allowSFTP = true;
                  kbdInteractiveAuthentication = false;
                  enable = true;
                  forwardX11 = true;
                  passwordAuthentication = false;
                  permitRootLogin = "yes";
                  ports = [ 10022 ];
                  authorizedKeysFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];
                };

                # https://stackoverflow.com/a/71247061
                # https://nixos.wiki/wiki/Firewall
                networking.firewall = {
                  enable = true;
                  allowedTCPPorts = [ 22 80 443 10022 8000 ];
                };

                programs.ssh.forwardX11 = true;
                services.qemuGuest.enable = true;

                services.sshd.enable = true;

                programs.dconf.enable = true;

                time.timeZone = "America/Recife";
                system.stateVersion = "22.11";

                users.users.root = {
                  password = "root";
                  initialPassword = "root";
                  openssh.authorizedKeys.keyFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];
                };
              })
            ];
        };


      nixosConfigurations.nixosBuildVMAarch64LinuxPodman =
        let
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config = { allowUnfree = true; };
          };
        in
        nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          # system = "aarch64-linux";
          modules =
            let
              nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly";
            in
            [
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/build-vm.nix"
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-vm.nix"
              # "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-guest.nix"
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/installer/cd-dvd/channel.nix"

              ({
                # https://gist.github.com/andir/88458b13c26a04752854608aacb15c8f#file-configuration-nix-L11-L12
                boot.loader.grub.extraConfig = "serial --unit=0 --speed=115200 \n terminal_output serial console; terminal_input serial console";
                boot.kernelParams = [
                  "console=tty0"
                  "console=ttyS0,115200n8"
                  # Set sensible kernel parameters
                  # https://nixos.wiki/wiki/Bootloader
                  # https://git.redbrick.dcu.ie/m1cr0man/nix-configs-rb/commit/ddb4d96dacc52357e5eaec5870d9733a1ea63a5a?lang=pt-PT
                  "boot.shell_on_fail"
                  "panic=30"
                  "boot.panic_on_fail" # reboot the machine upon fatal boot issues
                  # TODO: test it
                  "intel_iommu=on"
                  "iommu=pt"

                  # https://discuss.linuxcontainers.org/t/podman-wont-run-containers-in-lxd-cgroup-controller-pids-unavailable/13049/2
                  # https://github.com/NixOS/nixpkgs/issues/73800#issuecomment-729206223
                  # https://github.com/canonical/microk8s/issues/1691#issuecomment-977543458
                  # https://github.com/grahamc/nixos-config/blob/35388280d3b06ada5882d37c5b4f6d3baa43da69/devices/petunia/configuration.nix#L36
                  # cgroup_no_v1=all
                  "swapaccount=0"
                  "systemd.unified_cgroup_hierarchy=0"
                  "group_enable=memory"
                ];

                boot.tmpOnTmpfs = false;
                # https://github.com/AtilaSaraiva/nix-dotfiles/blob/main/lib/modules/configHost/default.nix#L271-L273
                boot.tmpOnTmpfsSize = "100%";

                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;

                users.users.nixuser = {
                  isSystemUser = true;
                  password = "1";
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "podman"
                    "kvm"
                    "libvirtd"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    direnv
                    gitFull
                    xorg.xclock
                    file
                    btop
                    # pkgsCross.aarch64-multiplatform-musl.pkgsStatic.hello

                    # firefox
                    # vscode
                    # (python3.buildEnv.override
                    #   {
                    #     extraLibs = with python3Packages; [ scikitimage opencv2 numpy ];
                    #   }
                    # )
                  ];
                  shell = pkgs.bashInteractive;
                  uid = 1234;
                  autoSubUidGidRange = true;

                  openssh.authorizedKeys.keyFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];

                  openssh.authorizedKeys.keys = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly"
                  ];
                };

                systemd.services.adds-change-workdir = {
                  script = "echo cd /tmp/shared >> /home/nixuser/.profile";
                  wantedBy = [ "multi-user.target" ];
                };

                systemd.services.creates-if-not-exist = {
                  script = "echo touch /home/nixuser/.Xauthority >> /home/nixuser/.profile";
                  wantedBy = [ "multi-user.target" ];
                };

                # https://unix.stackexchange.com/questions/619671/declaring-a-sym-link-in-a-users-home-directory#comment1159159_619703
                systemd.services.populate-history = {
                  script = "echo \"ls -al /nix/store\" >> /home/nixuser/.bash_history";
                  wantedBy = [ "multi-user.target" ];
                };

                virtualisation = {
                  # following configuration is added only when building VM with build-vm
                  memorySize = 3072; # Use MiB memory.

                  # nixos-disk-image> ERROR: cptofs failed. diskSize might be too small for closure.
                  diskSize = 15*1024; # Use MiB memory.
                  cores = 7; # Simulate 3 cores.
                  #
                  podman.enable = true;

                  #
                  useNixStoreImage = true;
                  writableStore = true; # TODO

                  # https://github.com/nix-community/nixos-generators/blob/10079333313ff62446e6f2b0e7c5231c7431d269/formats/vm-nogui.nix#L17C1-L18
                  # graphics = false;
                  # qemu.options = [ "-serial mon:stdio -display none -monitor none" ];
                  qemu.options = [ "-display none -monitor none -daemonize" ];
                };
                security.polkit.enable = true;

                # https://nixos.wiki/wiki/Libvirt
                boot.extraModprobeConfig = "options kvm_intel nested=1";
                boot.kernelModules = [
                  "kvm-intel"
                  "vfio-pci"
                ];

                # hardware.opengl.enable = true;
                # hardware.opengl.driSupport = true;

                nixpkgs.config.allowUnfree = true;
                nix = {
                  package = pkgs.nix;
                  # package = pkgsCross.aarch64-multiplatform-musl.pkgsStatic.nix;
                  extraOptions = "experimental-features = nix-command flakes";
                  readOnlyStore = true;
                };

                boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

                # Enable the X11 windowing system.
                services.xserver = {
                  enable = true;
                  displayManager.gdm.enable = true;
                  displayManager.startx.enable = true;
                  logFile = "/var/log/X.0.log";
                  desktopManager.xterm.enable = true;
                  # displayManager.gdm.autoLogin.enable = true;
                  # displayManager.gdm.autoLogin.user = "nixuser";
                };
                services.spice-vdagentd.enable = true;

                # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
                services.openssh = {
                  allowSFTP = true;
                  kbdInteractiveAuthentication = false;
                  enable = true;
                  forwardX11 = true;
                  passwordAuthentication = false;
                  permitRootLogin = "yes";
                  ports = [ 10022 ];
                  authorizedKeysFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];
                };

                # https://stackoverflow.com/a/71247061
                # https://nixos.wiki/wiki/Firewall
                networking.firewall = {
                  enable = true;
                  allowedTCPPorts = [ 22 80 443 10022 8000 ];
                };

                programs.ssh.forwardX11 = true;
                services.qemuGuest.enable = true;

                services.sshd.enable = true;

                programs.dconf.enable = true;

                time.timeZone = "America/Recife";
                system.stateVersion = "22.11";

                users.users.root = {
                  password = "root";
                  initialPassword = "root";
                  openssh.authorizedKeys.keyFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];
                };
              })
            ];
        };

      nixosConfigurations.nixosBuildVMX86_64LinuxDocker =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config = { allowUnfree = true; };
          };
        in
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # system = "aarch64-linux";
          modules =
            let
              nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly";
            in
            [
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/build-vm.nix"
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-vm.nix"
              # "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-guest.nix"
              "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/installer/cd-dvd/channel.nix"

              ({
                # https://gist.github.com/andir/88458b13c26a04752854608aacb15c8f#file-configuration-nix-L11-L12
                boot.loader.grub.extraConfig = "serial --unit=0 --speed=115200 \n terminal_output serial console; terminal_input serial console";
                boot.kernelParams = [
                  "console=tty0"
                  "console=ttyS0,115200n8"
                  # Set sensible kernel parameters
                  # https://nixos.wiki/wiki/Bootloader
                  # https://git.redbrick.dcu.ie/m1cr0man/nix-configs-rb/commit/ddb4d96dacc52357e5eaec5870d9733a1ea63a5a?lang=pt-PT
                  "boot.shell_on_fail"
                  "panic=30"
                  "boot.panic_on_fail" # reboot the machine upon fatal boot issues
                  # TODO: test it
                  "intel_iommu=on"
                  "iommu=pt"

                  # https://discuss.linuxcontainers.org/t/podman-wont-run-containers-in-lxd-cgroup-controller-pids-unavailable/13049/2
                  # https://github.com/NixOS/nixpkgs/issues/73800#issuecomment-729206223
                  # https://github.com/canonical/microk8s/issues/1691#issuecomment-977543458
                  # https://github.com/grahamc/nixos-config/blob/35388280d3b06ada5882d37c5b4f6d3baa43da69/devices/petunia/configuration.nix#L36
                  # cgroup_no_v1=all
                  "swapaccount=0"
                  "systemd.unified_cgroup_hierarchy=0"
                  "group_enable=memory"
                ];

                boot.tmpOnTmpfs = false;
                # https://github.com/AtilaSaraiva/nix-dotfiles/blob/main/lib/modules/configHost/default.nix#L271-L273
                boot.tmpOnTmpfsSize = "100%";

                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;

                users.users.nixuser = {
                  isSystemUser = true;
                  password = "1";
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "docker"
                    "kvm"
                    "libvirtd"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    direnv
                    gitFull
                    xorg.xclock
                    file
                    # pkgsCross.aarch64-multiplatform-musl.pkgsStatic.hello
                    btop
                    # firefox
                    # vscode
                    # (python3.buildEnv.override
                    #   {
                    #     extraLibs = with python3Packages; [ scikitimage opencv2 numpy ];
                    #   }
                    # )
                  ];
                  shell = pkgs.bashInteractive;
                  uid = 1234;
                  autoSubUidGidRange = true;

                  openssh.authorizedKeys.keyFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];

                  openssh.authorizedKeys.keys = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly"
                  ];
                };

                systemd.services.adds-change-workdir = {
                  script = "echo cd /tmp/shared >> /home/nixuser/.profile";
                  wantedBy = [ "multi-user.target" ];
                };

                systemd.services.creates-if-not-exist = {
                  script = "echo touch /home/nixuser/.Xauthority >> /home/nixuser/.profile";
                  wantedBy = [ "multi-user.target" ];
                };

                # https://unix.stackexchange.com/questions/619671/declaring-a-sym-link-in-a-users-home-directory#comment1159159_619703
                systemd.services.populate-history = {
                  script = "echo \"ls -al /nix/store\" >> /home/nixuser/.bash_history";
                  wantedBy = [ "multi-user.target" ];
                };

                virtualisation = {
                  # following configuration is added only when building VM with build-vm
                  memorySize = 3072; # Use MiB memory.
                  diskSize = 4096; # Use MiB memory.
                  cores = 7; # Simulate 3 cores.
                  #
                  docker.enable = true;

                  #
                  useNixStoreImage = true;
                  writableStore = true; # TODO
                };
                security.polkit.enable = true;

                environment.etc."containers/registries.conf" = {
                  mode = "0644";
                  text = ''
                    [registries.search]
                    registries = ['docker.io', 'localhost']
                  '';
                };

                # https://nixos.wiki/wiki/Libvirt
                boot.extraModprobeConfig = "options kvm_intel nested=1";
                boot.kernelModules = [
                  "kvm-intel"
                  "vfio-pci"
                ];

                # hardware.opengl.enable = true;
                # hardware.opengl.driSupport = true;

                nixpkgs.config.allowUnfree = true;
                nix = {
                  package = pkgs.nix;
                  # package = pkgsCross.aarch64-multiplatform-musl.pkgsStatic.nix;
                  extraOptions = "experimental-features = nix-command flakes";
                  readOnlyStore = true;
                };

                boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

                # Enable the X11 windowing system.
                services.xserver = {
                  enable = true;
                  displayManager.gdm.enable = true;
                  displayManager.startx.enable = true;
                  logFile = "/var/log/X.0.log";
                  desktopManager.xterm.enable = true;
                  # displayManager.gdm.autoLogin.enable = true;
                  # displayManager.gdm.autoLogin.user = "nixuser";
                };
                services.spice-vdagentd.enable = true;

                # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
                services.openssh = {
                  allowSFTP = true;
                  kbdInteractiveAuthentication = false;
                  enable = true;
                  forwardX11 = true;
                  passwordAuthentication = false;
                  permitRootLogin = "yes";
                  ports = [ 10022 ];
                  authorizedKeysFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];
                };

                # https://stackoverflow.com/a/71247061
                # https://nixos.wiki/wiki/Firewall
                networking.firewall = {
                  enable = true;
                  allowedTCPPorts = [ 22 80 443 10022 8000 ];
                };

                programs.ssh.forwardX11 = true;
                services.qemuGuest.enable = true;

                services.sshd.enable = true;

                programs.dconf.enable = true;

                time.timeZone = "America/Recife";
                system.stateVersion = "22.11";

                users.users.root = {
                  password = "root";
                  initialPassword = "root";
                  openssh.authorizedKeys.keyFiles = [
                    "${ ./nixuser-keys.pub }"
                  ];
                };
              })
            ];
        };

      nixosConfigurations.nixosBuildVMAarch64Linux =
        let
          pkgs = import nixpkgs {
            # system = "x86_64-linux";
            system = "aarch64-linux";
            config = { allowUnfree = true; };
          };
        in
        nixpkgs.lib.nixosSystem
          {
            system = "aarch64-linux";
            modules =
              let
                nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly";
              in
              [
                "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/build-vm.nix"
                "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-vm.nix"
                # "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-guest.nix"
                "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/installer/cd-dvd/channel.nix"

                ({
                  boot.kernelParams = [
                    "console=tty0"
                    "console=ttyAMA0,115200n8"
                    # Set sensible kernel parameters
                    # https://nixos.wiki/wiki/Bootloader
                    # https://git.redbrick.dcu.ie/m1cr0man/nix-configs-rb/commit/ddb4d96dacc52357e5eaec5870d9733a1ea63a5a?lang=pt-PT
                    "boot.shell_on_fail"
                    "panic=30"
                    "boot.panic_on_fail" # reboot the machine upon fatal boot issues
                    # TODO: test it
                    "intel_iommu=on"
                    "iommu=pt"

                    # https://discuss.linuxcontainers.org/t/podman-wont-run-containers-in-lxd-cgroup-controller-pids-unavailable/13049/2
                    # https://github.com/NixOS/nixpkgs/issues/73800#issuecomment-729206223
                    # https://github.com/canonical/microk8s/issues/1691#issuecomment-977543458
                    # https://github.com/grahamc/nixos-config/blob/35388280d3b06ada5882d37c5b4f6d3baa43da69/devices/petunia/configuration.nix#L36
                    # cgroup_no_v1=all
                    "swapaccount=0"
                    "systemd.unified_cgroup_hierarchy=0"
                    "group_enable=memory"
                  ];

                  boot.tmpOnTmpfs = false;
                  # https://github.com/AtilaSaraiva/nix-dotfiles/blob/main/lib/modules/configHost/default.nix#L271-L273
                  boot.tmpOnTmpfsSize = "100%";

                  # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                  users.extraGroups.nixgroup.gid = 999;

                  users.users.nixuser = {
                    isSystemUser = true;
                    password = "";
                    createHome = true;
                    home = "/home/nixuser";
                    homeMode = "0700";
                    description = "The VM tester user";
                    group = "nixgroup";
                    extraGroups = [
                      "podman"
                      "kvm"
                      "libvirtd"
                      "wheel"
                    ];
                    packages = with pkgs; [
                      direnv
                      file
                      gnumake
                      which
                      coreutils
                    ];
                    shell = pkgs.bashInteractive;
                    uid = 1234;
                    autoSubUidGidRange = true;

                    openssh.authorizedKeys.keyFiles = [
                      "${ ./nixuser-keys.pub }"
                    ];

                    openssh.authorizedKeys.keys = [
                      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly"
                    ];
                  };

                  virtualisation = {
                    # following configuration is added only when building VM with build-vm
                    memorySize = 3072; # Use MiB memory.
                    diskSize = 1024 * 16; # Use MiB memory.
                    cores = 6; # Simulate 6 cores.

                    #
                    docker.enable = false;
                    podman.enable = true;

                    #
                    useNixStoreImage = true;
                    writableStore = true; # TODO
                  };

                  nixpkgs.config.allowUnfree = true;
                  nix = {
                    # package = nixpkgs.pkgs.nix;
                    extraOptions = "experimental-features = nix-command flakes";
                    readOnlyStore = true;
                  };

                  # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
                  services.openssh = {
                    allowSFTP = true;
                    kbdInteractiveAuthentication = false;
                    enable = true;
                    forwardX11 = false;
                    passwordAuthentication = false;
                    permitRootLogin = "yes";
                    ports = [ 10022 ];
                    authorizedKeysFiles = [
                      "${ ./nixuser-keys.pub }"
                    ];
                  };

                  time.timeZone = "America/Recife";
                  system.stateVersion = "22.11";

                  users.users.root = {
                    password = "root";
                    initialPassword = "root";
                    openssh.authorizedKeys.keyFiles = [
                      "${ ./nixuser-keys.pub }"
                    ];
                  };
                })
              ];
          };

      packages.checkNixFormat = pkgsAllowUnfree.runCommand "check-nix-format" { } ''
        ${pkgsAllowUnfree.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}

        # For fix
        # find . -type f -iname '*.nix' -exec nixpkgs-fmt {} \;

        mkdir $out #sucess
      '';

      apps.${name} = flake-utils.lib.mkApp {
        inherit name;
        drv = packages.${name};
      };

      devShells.default = pkgsAllowUnfree.mkShell {
        buildInputs = with pkgsAllowUnfree; [
          bashInteractive
          coreutils
          curl
          gnumake
          patchelf
          # poetry
          python3Full
          tmate
          podman
        ];

        shellHook = ''
            echo -e 'IMO \n Banco' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat

            export NIXOS_VM_USER=nixuser
            export HOST_MAPPED_PORT=10022
            export REMOVE_DISK=true
            export QEMU_NET_OPTS=hostfwd=tcp::"$HOST_MAPPED_PORT"-:"$HOST_MAPPED_PORT",hostfwd=tcp::8000-:8000
            # export QEMU_OPTS="-nographic"
            # export QEMU_OPTS="-daemonize -display none -monitor none"
            export SHARED_DIR="$(pwd)"
            export RUN_BUID_VM_SCRIPT_PATH="''${self.nixosConfigurations.x86_64-linux.nixosBuildVMX86_64LinuxPodman.config.system.build.vm}"/bin/run-nixos-vm
            export CONTAINER_HOST=ssh://"$NIXOS_VM_USER"@localhost:"$HOST_MAPPED_PORT"/run/user/1234/podman/podman.sock

            "$REMOVE_DISK" && rm -fv nixos.qcow2

            # chmod 0600 .id_ed25519
            IDENTITY_FULL_PATH=./id_ed25519

            chmod -v 0600 "$IDENTITY_FULL_PATH"

            ssh-keygen -R '[localhost]:10022'
            ssh-add -l | grep -q 'SHA256:NzLgwADMD4taCNCdiTTRz0yyMdN0AguJVZD+eHiQZjE' || ssh-add "$IDENTITY_FULL_PATH"

            # ssh -T -i "$IDENTITY_FULL_PATH" -o ConnectTimeout=1 -o StrictHostKeyChecking=no nixuser@localhost -p "$HOST_MAPPED_PORT" <<<'systemctl is-active podman.socket' \
            # || ( "$RUN_BUID_VM_SCRIPT_PATH" & )

            # $("$RUN_BUID_VM_SCRIPT_PATH" < /dev/null &)&
            # "$RUN_BUID_VM_SCRIPT_PATH"

            # TODO: pq o podman.service não está ativo?
            # while ! ssh -T -i "$IDENTITY_FULL_PATH" -o ConnectTimeout=1 -o StrictHostKeyChecking=no nixuser@localhost -p "$HOST_MAPPED_PORT" <<<'systemctl is-active podman.socket'; do \
            #   echo $(date +'%d/%m/%Y %H:%M:%S:%3N'); sleep 0.5; done

        '';
      };
    });
}
