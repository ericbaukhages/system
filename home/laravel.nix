{ config, pkgs, ... }:

let
  # Build a single PHP 8.5 environment with the extensions Laravel needs.
  # Referencing this same `php` for Composer and the Laravel installer avoids
  # mixing PHP API versions (e.g. loading 8.4 extensions into an 8.5 binary).
  php = pkgs.php85.buildEnv {
    extensions = ({ enabled, all }: enabled);
    extraConfig = ''
      memory_limit = 512M
    '';
  };
in
{
  home.packages = [
    php
    php.packages.composer
    (pkgs.laravel.override { inherit php; })
    pkgs.sqlite
  ];
}
