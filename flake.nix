{
  inputs = {
    systems.url = "github:nix-systems/default";
    twist.url = "github:emacs-twist/twist.nix";
    emacs-ci.url = "github:purcell/nix-emacs-ci";
  };

  nixConfig = {
    extra-substituters = ["https://emacs-ci.cachix.org"];
    extra-trusted-public-keys = ["emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4="];
  };

  outputs = {
    systems,
    nixpkgs,
    self,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (
        system:
          f (import nixpkgs {
            inherit system;
            overlays = [
              inputs.twist.overlays.default
            ];
          })
      );

    # Darwin doesn't support all Emacs versions in nix-emacs-ci, so use Linux
    emacsPackages = inputs.emacs-ci.packages.x86_64-linux;
  in {
    data = import ./generated;

    lib.builtinLibrariesOfEmacsVersion = targetVersion: let
      xs =
        builtins.map ({libraries, ...}: libraries)
        (
          builtins.filter ({version, ...}: version == targetVersion)
          (builtins.attrValues self.data)
        );
    in
      if builtins.length xs > 0
      then builtins.head xs
      else null;

    devShells = eachSystem (pkgs: {
      default = pkgs.mkShell {buildInputs = [pkgs.just];};
    });

    packages = eachSystem (pkgs: {
      default = pkgs.linkFarm "default" (
        [
          {
            name = "default.nix";
            path = pkgs.writeText "emacs-builtins-default-nix" ''{${
                lib.concatMapStrings (
                  name: "${name} = import ./${name}.nix;\n"
                )
                (builtins.attrNames emacsPackages)
              }}'';
          }
        ]
        ++ (lib.mapAttrsToList (emacsName: emacsPackage: {
            name = "${emacsName}.nix";
            path =
              pkgs.runCommand "build-${emacsName}-builtins-nix" {
                buildInputs = [emacsPackage];
              } ''
                EMACS_VERSION="$(emacs --version \
                  | grep -F "GNU Emacs" \
                  | grep -oE "[[:digit:]]+(:?\.[[:digit:]]+)+")"
                echo >>$out '{'
                echo >>$out "  version = \"''${EMACS_VERSION}\";"
                echo >>$out '  libraries = ['
                sed -e 's/^/"/' -e 's/$/"/' ${(pkgs.emacsTwist {
                    inherit emacsPackage;
                    initFiles = [];
                    lockDir = null;
                    inventories = [];
                  })
                  .builtinLibraryList} >>$out
                echo >>$out '  ];'
                echo >>$out '}'
              '';
          })
          emacsPackages)
      );
    });
  };
}
