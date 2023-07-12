{ pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # Meshcentral for easy remote access
  # manual installation as Nix version is outdated
  # Also adding in a Python module needed for monitoring our PostgreSQL database via Netdata
  environment.systemPackages = with pkgs; [ python310Packages.psycopg2 nodejs ];
  systemd.services.meshcentral = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    environment = { "NODE_ENV" = "production"; };
    path = [ pkgs.nodejs ];
    serviceConfig = {
      ExecStart =
        ''"${pkgs.nodejs}/bin/node" /opt/meshcentral/node_modules/meshcentral'';
      Group = "meshcentral";
      PrivateTmp = "true";
      Restart = "always";
      RestartSec = 10;
      User = "meshcentral";
      WorkingDirectory = "/opt/meshcentral";
    };
  };

  # Create Meshcentral user and group for the service to use
  users.groups.meshcentral = { };
  users.users.meshcentral = {
    home = "/opt/meshcentral";
    group = "meshcentral";
    isNormalUser = true;
  };

  # Open up ports for Meshcentral
  networking.firewall.allowedTCPPorts = [ 22260 22261 ];

  system.stateVersion = "23.05";
}

