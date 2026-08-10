default:
    just --list

rebuild:
    sudo nixos-rebuild switch --flake .#t490s

check:
    nix flake check --all-systems

home:
    nix run home-manager -- switch --flake .#eric

home-darwin:
    nix run home-manager -- switch --flake .#eric-darwin

darwin:
    darwin-rebuild switch --flake .#eric-macbook

fmt:
    nix fmt
