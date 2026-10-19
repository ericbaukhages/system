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
                opencode =
                  let
                    version = "2.0.32";
                    platform =
                      {
                        x86_64-linux = {
                          name = "linux-x64";
                          hash = "sha256-ZKH0s4HC0u/BjI12ss45kUF3i0IbVMmLlL6OgIA2Btw=";
                        };
                        aarch64-linux = {
                          name = "linux-arm64";
                          hash = "sha256-uEkjLsYdm2JNHEieVpWfU5Vm6xT45bKvXFTvI3EYz2M=";
                        };
                        x86_64-darwin = {
                          name = "darwin-x64";
                          hash = "sha256-7Plc1SLwtI5JL7yL/kvMORZT2g/uaQ/dHSStrck+QvA=";
                        };
                        aarch64-darwin = {
                          name = "darwin-arm64";
                          hash = "sha256-YtilJWZDspeEI/jpcb3IiW0sE8rAg4DRpd2UbM66Cas=";
                        };
                      }
                      .${system} or (throw "Unsupported system for opencode: ${system}");
                    isLinux = prev.stdenvNoCC.hostPlatform.isLinux;
                  in
                  prev.stdenvNoCC.mkDerivation {
                    pname = "opencode";
                    inherit version;
                    src = prev.fetchurl {
                      url = "https://registry.npmjs.org/@opencode/cli-${platform.name}/-/cli-${platform.name}-${version}.tgz";
                      inherit (platform) hash;
                    };
                    nativeBuildInputs = prev.lib.optionals isLinux [ prev.patchelf ];
                    installPhase = ''
                      runHook preInstall
                      install -Dm755 bin/opencode $out/bin/opencode
                      ${prev.lib.optionalString isLinux ''
                        patchelf \
                          --set-interpreter ${prev.stdenv.cc.bintools.dynamicLinker} \
                          --set-rpath ${prev.lib.makeLibraryPath [ prev.glibc ]} \
                          $out/bin/opencode
                      ''}
                      runHook postInstall
                    '';
                    doInstallCheck = prev.stdenvNoCC.buildPlatform.canExecute prev.stdenvNoCC.hostPlatform;
                    nativeInstallCheckInputs = [ prev.versionCheckHook ];
                    versionCheckProgramArg = "--version";
                    meta = {
                      description = "Open source AI coding agent";
                      homepage = "https://opencode.ai";
                      license = prev.lib.licenses.mit;
                      mainProgram = "opencode";
                      platforms = [
                        "x86_64-linux"
                        "aarch64-linux"
                        "x86_64-darwin"
                        "aarch64-darwin"
                      ];
                    };
                  };
                token-monitor =
                  let
                    version = "0.75.0";
                    pname = "token-monitor";
                    isLinux = prev.stdenvNoCC.hostPlatform.isLinux;
                    isDarwin = prev.stdenvNoCC.hostPlatform.isDarwin;
                  in
                  if isLinux then
                    let
                      src = prev.fetchurl {
                        url = "https://github.com/Javis603/token-monitor/releases/download/v${version}/Token-Monitor-${version}.AppImage";
                        hash = "sha256-UmI7XzvTi0n4KTHwsLkixtrSsJ2vf4M7TyWJJfn2qNk=";
                      };
                      appimageContents = prev.appimageTools.extractType2 { inherit pname version src; };
                    in
                    prev.appimageTools.wrapType2 {
                      inherit pname version src;
                      extraInstallCommands = ''
                        install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
                        substituteInPlace $out/share/applications/${pname}.desktop \
                          --replace-fail 'Exec=AppRun' 'Exec=${pname}'
                        cp -r ${appimageContents}/usr/share/icons $out/share
                      '';
                      meta = {
                        description = "Desktop widget for tracking token usage, costs, limits, and session activity across AI coding tools";
                        homepage = "https://github.com/Javis603/token-monitor";
                        license = prev.lib.licenses.mit;
                        mainProgram = pname;
                        platforms = [ "x86_64-linux" ];
                        sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
                      };
                    }
                  else if isDarwin then
                    let
                      platform =
                        {
                          aarch64-darwin = {
                            suffix = "arm64";
                            hash = "sha256-85r5XSWp+2kgBYn5g1W9u9L+E5R2tWcdM0cKAT6IowE=";
                          };
                          x86_64-darwin = {
                            suffix = "x64";
                            hash = "sha256-sUqzV57OcBLBbdSm8Dls2iHP1UUKnJMJNdmrIp4uYAs=";
                          };
                        }
                        .${prev.stdenvNoCC.hostPlatform.system}
                          or (throw "Unsupported system for token-monitor: ${prev.stdenvNoCC.hostPlatform.system}");
                      src = prev.fetchurl {
                        url = "https://github.com/Javis603/token-monitor/releases/download/v${version}/Token-Monitor-${version}-${platform.suffix}.dmg";
                        inherit (platform) hash;
                      };
                    in
                    prev.stdenvNoCC.mkDerivation {
                      inherit pname version src;
                      nativeBuildInputs = [
                        prev.makeWrapper
                        prev._7zz
                      ];
                      sourceRoot = ".";
                      installPhase = ''
                        runHook preInstall
                        mkdir -p $out/Applications $out/bin
                        appdir=$(find . -maxdepth 2 -name "*.app" -type d | head -n1)
                        cp -R "$appdir" $out/Applications/"Token Monitor.app"
                        makeWrapper "$out/Applications/Token Monitor.app/Contents/MacOS/Token Monitor" $out/bin/${pname}
                        runHook postInstall
                      '';
                      meta = {
                        description = "Desktop widget for tracking token usage, costs, limits, and session activity across AI coding tools";
                        homepage = "https://github.com/Javis603/token-monitor";
                        license = prev.lib.licenses.mit;
                        platforms = [
                          "aarch64-darwin"
                          "x86_64-darwin"
                        ];
                        sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
                      };
                    }
                  else
                    throw "Unsupported system for token-monitor: ${prev.stdenvNoCC.hostPlatform.system}";
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
