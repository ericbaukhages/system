{ vars, ... }:

{
  networking.networkmanager.enable = true;

  users.users.${vars.userName}.extraGroups = [ "networkmanager" ];
}
