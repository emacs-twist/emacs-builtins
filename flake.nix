{
  inputs = {
    systems.url = "github:nix-systems/default";
    twist.url = "github:emacs-twist/twist.nix";
    emacs-ci.url = "github:purcell/nix-emacs-ci";
  };

  outputs = {
    systems,
    nixpkgs,
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
                  name: "${name} = (import ./${name}.nix).libraries;\n"
                )
                (builtins.attrNames emacsPackages)
              }}'';
          }
        ]
        ++ (lib.mapAttrsToList (emacsName: emacsPackage: {
            name = "${emacsName}.nix";
            path =
              pkgs.runCommand "build-${emacsName}-builtins-nix" {
              } ''
                echo >>$out '{'
                echo >>$out '  version = "${emacsPackage.version}";'
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
