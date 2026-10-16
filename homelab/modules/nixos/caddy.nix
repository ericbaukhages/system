{ ... }:

{
  services.caddy = {
    enable = true;
    extraConfig = ''
      :80 {
        respond "x250 homelab placeholder"
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
