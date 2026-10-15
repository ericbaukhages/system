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
                secretspec = nixpkgs-unstable.legacyPackages.${system}.secretspec;
                yt-dlp = nixpkgs-unstable.legacyPackages.${system}.yt-dlp;
                ghgrab = ghgrab.packages.${system}.default;
                leaf = prev.rustPlatform.buildRustPackage {
                  pname = "leaf";
                  version = "1.28.2";
                  src = leaf;
                  cargoLock.lockFile = leaf + "/Cargo.lock";
                };
                todoist = final.buildNpmPackage {
                  pname = "todoist-cli";
                  version = "5.4.3";
                  src = final.fetchFromGitHub {
                    owner = "Doist";
                    repo = "todoist-cli";
                    rev = "v5.4.3";
                    hash = "sha256-9WKTOmO4NPL1Lmu82FRaSLiBhugfffp/PDks4cfxczM=";
                  };
                  npmDepsHash = "sha256-LhzRlfvKkQBfx3K0dS6D0cdrVFEjkqHk+F2lMHRpdbk=";
                };

                # Wasp CLI ships as an npm wrapper around platform-specific
                # binaries. We bypass the Node wrapper and call the binary
                # directly with its data directory.
                wasp =
                  let
                    version = "0.25.0";
                    platformInfo = {
                      x86_64-linux = {
                        name = "linux-x64-glibc";
                        hash = "sha256-ceM95ZbOdUq+5KBUhxIZb0CBrCWkLemO6iIjzhiHfo4=";
                      };
                      aarch64-linux = {
                        name = "linux-arm64-glibc";
                        hash = "sha256-IXaAH2gbxcwlDJt3aDHPhaKNiGmhnEqhHqGFYV55p7Y=";
                      };
                      x86_64-darwin = {
                        name = "darwin-x64-unknown";
                        hash = "sha256-BM7/1y4fX6sZ08miFYluF8n6kK0KqZRsoKlH+TPP39M=";
                      };
                      aarch64-darwin = {
                        name = "darwin-arm64-unknown";
                        hash = "sha256-EAWK//ropRPQEUmgOTsilD+BGZmRTQhn6DkiKwwayts=";
                      };
                    };
                    selected =
                      platformInfo.${prev.stdenv.hostPlatform.system}
                        or (throw "wasp is not supported on ${prev.stdenv.hostPlatform.system}");
                  in
                  prev.stdenv.mkDerivation {
                    pname = "wasp";
                    inherit version;
                    src = prev.fetchurl {
                      url = "https://registry.npmjs.org/@wasp.sh/wasp-cli-${selected.name}/-/wasp-cli-${selected.name}-${version}.tgz";
                      hash = selected.hash;
                    };
                    nativeBuildInputs = [
                      prev.makeWrapper
                    ]
                    ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [ prev.autoPatchelfHook ];
                    buildInputs = prev.lib.optionals prev.stdenv.hostPlatform.isLinux [
                      prev.zlib
                      prev.gmp
                    ];
                    installPhase = ''
                      runHook preInstall
                      mkdir -p $out/bin $out/lib/wasp $out/share/wasp
                      cp wasp-bin $out/lib/wasp/
                      cp -r data $out/share/wasp/
                      makeWrapper $out/lib/wasp/wasp-bin $out/bin/wasp \
                        --set waspc_datadir $out/share/wasp/data
                      runHook postInstall
                    '';
                    meta = {
                      description = "Wasp CLI";
                      homepage = "https://wasp.sh";
                      license = prev.lib.licenses.mit;
                      platforms = prev.lib.attrNames platformInfo;
                      sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
                    };
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
