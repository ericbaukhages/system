{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # PHP 8.5 and Composer, as recommended by Laravel's php.new installer.
    php85
    php85Packages.composer

    # Laravel application installer CLI.
    laravel

    # SQLite CLI for the default Laravel SQLite database.
    sqlite
  ];
}
