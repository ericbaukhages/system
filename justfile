default:
    just --list

rebuild:
    sudo nixos-rebuild switch --flake .

check:
    nix flake check --all-systems

home:
    nix run home-manager -- switch --flake .#eric

home-darwin:
    nix run home-manager -- switch --flake .#eric-darwin

fmt:
    nixfmt .
