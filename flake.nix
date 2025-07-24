{
  description = "Zig project flake";

  inputs = {
    zig2nix.url = "github:Cloudef/zig2nix";
  };

  outputs = { zig2nix, ... }: let
    flake-utils = zig2nix.inputs.flake-utils;
  in (flake-utils.lib.eachDefaultSystem (system: let
      # Zig flake helper
      # Check the flake.nix in zig2nix project for more options:
      # <https://github.com/Cloudef/zig2nix/blob/master/flake.nix>
      env = zig2nix.outputs.zig-env.${system} {};
    in with builtins; with env.pkgs.lib; rec {
      # Produces clean binaries meant to be ship'd outside of nix
      # nix build .#foreign
      packages.foreign = env.package {
        src = cleanSource ./.;

        # Packages required for compiling
        nativeBuildInputs = with env.pkgs; [];

        # Packages required for linking
        buildInputs = with env.pkgs; [
          xorg.libX11
        ];

        # Smaller binaries and avoids shipping glibc.
        zigPreferMusl = true;
      };

      # nix build .
      packages.default = packages.foreign.override (attrs: {
        # Prefer nix friendly settings.
        zigPreferMusl = false;

        # Executables required for runtime
        # These packages will be added to the PATH
        zigWrapperBins = with env.pkgs; [];

        # Libraries required for runtime
        # These packages will be added to the LD_LIBRARY_PATH
        zigWrapperLibs = attrs.buildInputs or [];
      });

      # nix run .#build
      apps.build = env.app [] "zig build \"$@\"";

      # nix run .#zig2nix
      apps.zig2nix = env.app [] "zig2nix \"$@\"";

      # nix develop
      devShells.default = env.mkShell {
        # Packages required for compiling, linking and running
        # Libraries added here will be automatically added to the LD_LIBRARY_PATH and PKG_CONFIG_PATH
        nativeBuildInputs = []
          ++ packages.default.nativeBuildInputs
          ++ packages.default.buildInputs
          ++ packages.default.zigWrapperBins
          ++ packages.default.zigWrapperLibs;
      };
    }));
}
