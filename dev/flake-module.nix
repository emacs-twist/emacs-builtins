{ inputs, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      self',
      lib,
      ...
    }:
    let
      emacsPackages = inputs.emacs-ci.packages.${system};
    in
    {
      _module.args.pkgs = inputs.nixpkgs.legacyPackages.${system}.extend inputs.twist.overlays.default;

      devShells = {
        default = pkgs.mkShell { buildInputs = [ pkgs.just ]; };
      };

      packages = {
        default = pkgs.linkFarm "default" (
          [
            {
              name = "default.nix";
              path = pkgs.writeText "emacs-builtins-default-nix" ''{${
                lib.concatMapStrings (name: "${name} = import ./${name}.nix;\n") (builtins.attrNames emacsPackages)
              }}'';
            }
          ]
          ++ (lib.mapAttrsToList (emacsName: emacsPackage: {
            name = "${emacsName}.nix";
            path =
              pkgs.runCommand "build-${emacsName}-builtins-nix"
                {
                  buildInputs = [ emacsPackage ];
                }
                ''
                  EMACS_VERSION="$(emacs --version \
                    | grep -F "GNU Emacs" \
                    | grep -oE "[[:digit:]]+(:?\.[[:digit:]]+)+")"
                  echo >>$out '{'
                  echo >>$out "  version = \"''${EMACS_VERSION}\";"
                  echo >>$out '  libraries = ['
                  sed -e 's/^/"/' -e 's/$/"/' ${
                    (pkgs.emacsTwist {
                      inherit emacsPackage;
                      initFiles = [ ];
                      lockDir = null;
                      inventories = [ ];
                    }).builtinLibraryList
                  } >>$out
                  echo >>$out '  ];'
                  echo >>$out '}'
                '';
          }) emacsPackages)
        );
      };
    };
}
