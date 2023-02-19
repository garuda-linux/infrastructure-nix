{ garuda-lib, ... }: {
  imports = [ ./hardware-configuration.nix ./garuda/garuda.nix ];

  # Oracle provides DHCP
  networking.useDHCP = false;
  networking.interfaces.enp0s3.useDHCP = true;
  networking.hostName = "oracle-dragon";

  # The docker-compose stack holding Whoogle & Searx
  services.docker-compose-runner.oracle-dragon = {
    source = ./docker-compose/oracle-dragon;
    envfile = garuda-lib.secrets.docker-compose.oracle-dragon;
  };

  system.stateVersion = "22.11";
}
