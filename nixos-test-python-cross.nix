  let
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/d50918bc1c43dea8fd5282dcaca3ebc7144e210f");
    pkgs = import nixpkgs { };
  in
    pkgs.nixosTest ({
      name = "nixos-test-python-cross";
      nodes = {
        machineA = { config, pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            file
            pkgsCross.aarch64-multiplatform.pkgsStatic.python3
          ];
        };

        machineB = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.aarch64-multiplatform.pkgsStatic.python3
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
            pkgs.pkgsCross.s390x.pkgsStatic.python3
          ];
        };

        machineD = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.riscv64.pkgsStatic.python3
          ];
        };

        machineE = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "armv7l-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.armv7l-hf-multiplatform.pkgsStatic.python3
          ];
        };

        machineF = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "armv6l-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.raspberryPi.pkgsStatic.python3
          ];
        };

      };

      testScript = ''
        machineA.succeed("! python3 | grep -q -F -e ' exec format error: '")
        machineA.succeed("file $(readlink -f $(which python3)) | grep -q -F -e ': ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, not stripped'")
        machineA.succeed("! ldd $(readlink -f $(which python3)) | grep -q -F -e 'not a dynamic executable'")
        machineA.succeed("! patchelf --print-needed $(readlink -f $(which python3)) | grep -q -F -e 'patchelf: cannot find section '.dynamic'. The input file is most likely statically linked'")
        machineA.succeed("! readelf --dynamic $(readlink -f $(which python3)) | grep -q -F -e 'There  is no dynamic section in this file.'")

        machineB.succeed("python3 --version | grep -q -F -e '3.11.8'")
        machineC.succeed("python3 --version | grep -q -F -e '3.11.8'")
        machineD.succeed("python3 --version | grep -q -F -e '3.11.8'")
        machineE.succeed("python3 --version | grep -q -F -e '3.11.8'")
        machineF.succeed("python3 --version | grep -q -F -e '3.11.8'")
      '';
    })