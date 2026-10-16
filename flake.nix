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

    # Experimental CLI tools in the trials set (see home/trials/).
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
                secretspec = nixpkgs-unstable.legacyPackages.${system}.secretspec;
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
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      nixosConfigurations = {
        t490s = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit vars; };
          modules = [ ./workstation/hosts/t490s/configuration.nix ];
        };

        x250 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit vars; };
          modules = [ ./homelab/hosts/x250/configuration.nix ];
        };
      };

      darwinConfigurations = {
        eric-macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit vars; };
          modules = [ ./darwin/hosts/eric-macbook/configuration.nix ];
        };
      };

      homeConfigurations = {
        eric = mkHome "x86_64-linux";
        eric-darwin = mkHome "aarch64-darwin";
      };
    };
}
