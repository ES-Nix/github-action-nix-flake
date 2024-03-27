  let
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/d50918bc1c43dea8fd5282dcaca3ebc7144e210f");
    pkgs = import nixpkgs { };
  in
    pkgs.nixosTest ({
      name = "nixos-test-hello-cross";
      nodes = {
        machineA = { config, pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            file
            pkgsCross.aarch64-multiplatform.pkgsStatic.hello
          ];
        };

        machineB = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.aarch64-multiplatform.pkgsStatic.hello
          ];
        };

        machineC = { config, pkgs, ... }: {
          boot.binfmt.registrations = {
            s390x-linux = {
              # interpreter = getEmulator "s390x-linux";
              interpreter = "${pkgs.qemu}/bin/qemu-s390x";
              magicOrExtension = ''\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x16'';
              mask = ''\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff'';
            };
          };
          environment.systemPackages = [
            pkgs.pkgsCross.s390x.pkgsStatic.hello
          ];
        };

        machineD = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.riscv64.pkgsStatic.hello
          ];
        };

        machineE = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "armv7l-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.armv7l-hf-multiplatform.pkgsStatic.hello
          ];
        };

        machineF = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "armv6l-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.raspberryPi.pkgsStatic.hello
          ];
        };

      };

      testScript = ''
        machineA.succeed("! hello | grep -q -F -e ' exec format error: '")
        machineA.succeed("file $(readlink -f $(which hello)) | grep -q -F -e ': ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, not stripped'")
        machineA.succeed("! ldd $(readlink -f $(which hello)) | grep -q -F -e 'not a dynamic executable'")
        machineA.succeed("! patchelf --print-needed $(readlink -f $(which hello)) | grep -q -F -e 'patchelf: cannot find section '.dynamic'. The input file is most likely statically linked'")
        machineA.succeed("! readelf --dynamic $(readlink -f $(which hello)) | grep -q -F -e 'There  is no dynamic section in this file.'")

        machineB.succeed("hello | grep -q -F -e 'Hello, world!'")
        machineC.succeed("hello | grep -q -F -e 'Hello, world!'")
        machineD.succeed("hello | grep -q -F -e 'Hello, world!'")
        machineE.succeed("hello | grep -q -F -e 'Hello, world!'")
        machineF.succeed("hello | grep -q -F -e 'Hello, world!'")
      '';
    })
