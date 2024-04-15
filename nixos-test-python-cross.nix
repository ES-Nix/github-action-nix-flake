  let
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/d50918bc1c43dea8fd5282dcaca3ebc7144e210f");
    pkgs = import nixpkgs { };
  in
    pkgs.nixosTest ({
      name = "nixos-test-python-cross";
      nodes = {
        machineA = { config, pkgs, ... }: {
          environment.systemPackages = [
            pkgs.file
            (pkgs.python3.withPackages
              (pyPkgs: with pyPkgs; [ numpy ])
            )
          ];
        };

        machineB = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
          environment.systemPackages = [
            (pkgs.pkgsCross.aarch64-multiplatform.python3.withPackages
              (pyPkgs: with pyPkgs; [ numpy ])
            )
          ];
        };

        machineD = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
          environment.systemPackages = [
            (pkgs.pkgsCross.riscv64.python3.withPackages
              (pyPkgs: with pyPkgs; [ numpy ])
            )
          ];
        };

        machineE = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "armv7l-linux" ];
          environment.systemPackages = [
            (pkgs.pkgsCross.armv7l-hf-multiplatform.python3.withPackages
              (pyPkgs: with pyPkgs; [ numpy ])
            )
          ];
        };

        machineF = { config, pkgs, ... }: {
          boot.binfmt.emulatedSystems = [ "armv6l-linux" ];
          environment.systemPackages = [
            pkgs.pkgsCross.raspberryPi.pkgsStatic.python3
            (pkgs.pkgsCross.raspberryPi.python3.withPackages
              (pyPkgs: with pyPkgs; [ numpy ])
            )
          ];
        };
      };

      testScript = let
        testCommand = ''
          python3 \
          -c \
          '
          import numpy as np;
          np.array_equal(np.array([1,2]), np.sqrt(np.square(np.array([1,2]))))
          '
        '';
      in ''
        machineA.succeed("${testCommand}")
        machineB.succeed("${testCommand}")
        machineD.succeed("${testCommand}")
        machineE.succeed("${testCommand}")
        machineF.succeed("${testCommand}")
      '';
    })
