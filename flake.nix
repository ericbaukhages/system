{
  description = "Eric's system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CLI tools to try (see docs/plans/cli-tools-to-try.md).
    ghgrab = {
      url = "github:abhixdd/ghgrab/v2.0.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tuxedo = {
      url = "github:webstonehq/tuxedo/v2026.8.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kew = {
      url = "github:ravachol/kew/v4.3.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Markdown TUI previewer (no upstream flake, source-only input).
    leaf = {
      url = "github:RivoLink/leaf/1.28.2";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-darwin,
      ghgrab,
      tuxedo,
      kew,
      leaf,
      ...
    }:
    let
      vars = import ./vars.nix;
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      mkHome =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                yt-dlp = nixpkgs-unstable.legacyPackages.${system}.yt-dlp;
                ghgrab = ghgrab.packages.${system}.default;
                leaf = prev.rustPlatform.buildRustPackage {
                  pname = "leaf";
                  version = "1.28.2";
                  src = leaf;
                  cargoLock.lockFile = leaf + "/Cargo.lock";
                };
              })
              tuxedo.overlays.default
              kew.overlays.default
            ];
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit vars; };
          modules = [ ./home ];
        };

      mkNixOS =
        host: system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit vars; };
          modules = [ ./hosts/${host}/configuration.nix ];
        };

      mkDarwin =
        host: system:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit vars; };
          modules = [ ./hosts/${host}/configuration.nix ];
        };
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      nixosConfigurations = {
        t490s = mkNixOS "t490s" "x86_64-linux";
        x250 = mkNixOS "x250" "x86_64-linux";
      };

      darwinConfigurations = {
        eric-macbook = mkDarwin "eric-macbook" "aarch64-darwin";
      };

      homeConfigurations = {
        eric = mkHome "x86_64-linux";
        eric-darwin = mkHome "aarch64-darwin";
      };
    };
}
