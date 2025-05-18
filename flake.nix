{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  nixConfig = {
    extra-substituters = [ "https://emacs-ci.cachix.org" ];
    extra-trusted-public-keys = [
      "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4="
    ];
  };

  outputs =
    { nixpkgs, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Darwin doesn't support all Emacs versions in nix-emacs-ci, so use Linux
      systems = [
        "x86_64-linux"
      ];

      imports = [
        inputs.flake-parts.flakeModules.partitions
      ];

      partitionedAttrs = {
        packages = "dev";
        checks = "dev";
        devShells = "dev";
      };

      partitions = {
        dev = {
          extraInputsFlake = ./dev;
          module = ./dev/flake-module.nix;
        };
      };

      flake =
        let
          data = import ./generated;
        in
        {
          inherit data;

          lib.builtinLibrariesOfEmacsVersion =
            targetVersion:
            let
              xs = builtins.map ({ libraries, ... }: libraries) (
                builtins.filter ({ version, ... }: version == targetVersion) (builtins.attrValues data)
              );
            in
            if builtins.length xs > 0 then builtins.head xs else null;
        };
    };
}
