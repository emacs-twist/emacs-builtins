default: update

update:
    mkdir -p generated
    rm -f generated/*.nix
    install -m 644 $(nix build . --print-out-paths)/*.nix generated/

check-function:
    nix eval .\#lib.builtinLibrariesOfEmacsVersion --apply 'f: f "29.1"'
