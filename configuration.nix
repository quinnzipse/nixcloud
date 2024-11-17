{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    ./tailscale.nix 
    ./nextcloud.nix
  ];

  users = {
    motdFile = "/etc/motd";
    users = {
      "INSERT_USERNAME_HERE" = {
        initialPassword = "PASSWORD";
        isNormalUser = true;
        openssh.authorizedKeys.keys = ["try putting an ssh key here :)"];
        extraGroups = ["wheel"];
      };
    };

  };
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
    listenAddresses = [
      {
        addr = "Your_ip_address_would_look_good_here";
        port = "Try your favorite number (probably above 1024)";
      }
    ];
  };

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.nftables.enable = true;
  networking.firewall.enable = true;
  networking.hostName = "name your host";
  networking.domain = "like host name, but more domainy";
  system.stateVersion = "23.11";
}
