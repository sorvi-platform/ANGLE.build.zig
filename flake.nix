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
      env = zig2nix.outputs.zig-env.${system} { zig = zig2nix.outputs.packages.${system}.zig-0_15_2; };
    in with builtins; with env.pkgs.lib; rec {
      # nix build .
      packages.default = env.package {
        src = cleanSource ./.;

        # Packages required for compiling
        nativeBuildInputs = with env.pkgs; [];

        # Packages required for linking
        buildInputs = with env.pkgs; [];
      };

      # nix run .#build
      apps.build = env.app [] "zig build \"$@\"";

      # nix run .#update-deps
      apps.update-deps = with env.pkgs; env.app [ bash git coreutils ] "bash update-angle.bash";

      # nix develop
      devShells.default = env.mkShell {};
    }));
}
