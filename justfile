default:
    just --list

rebuild:
    sudo nixos-rebuild switch --flake .#t490s

rebuild-homelab:
    sudo nixos-rebuild switch --flake .#x250

darwin:
    darwin-rebuild switch --flake .#eric-macbook

check:
    nix flake check --all-systems

home:
    nix run home-manager -- switch --flake .#eric

home-darwin:
    nix run home-manager -- switch --flake .#eric-darwin

home-news:
    nix run home-manager -- news --flake .#eric

home-darwin-news:
    nix run home-manager -- news --flake .#eric-darwin

fmt:
    nix fmt
