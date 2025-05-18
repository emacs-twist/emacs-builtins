# This is a flake to track dependency-only inputs and outputs. See
# https://flake.parts/options/flake-parts-partitions.html
{
  inputs = {
    twist.url = "github:emacs-twist/twist.nix";
    emacs-ci.url = "github:purcell/nix-emacs-ci";
  };

  # This flake is only used for its inputs.
  outputs = _: { };
}
