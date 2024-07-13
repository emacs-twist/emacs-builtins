This flake exports the list of builtin libraries of each Emacs version.

This is used in [Rice](https://github.com/emacs-twist/elisp-rice) to expose
Emacs Lisp packages to the flake while avoiding IFD.
## Usage

``` nix
nix eval github:emacs-twist/emacs-builtins#data.emacs-29-1 --no-write-lock-file --json | jq
```
