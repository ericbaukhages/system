{
  description = "Eric's system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      vars = import ./vars.nix;

      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
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
    in
    {
      nixosConfigurations.nixos = mkNixOS "nixos" "x86_64-linux";

      homeConfigurations = {
        eric = mkHome "x86_64-linux";
        eric-darwin = mkHome "aarch64-darwin";
      };
    };
}
