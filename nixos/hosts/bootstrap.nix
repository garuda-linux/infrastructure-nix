{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "immortalis";
  networking.interfaces."eth0".ipv4.addresses = [{
    address = "116.202.208.112";
    prefixLength = 26;
  }];
  networking.defaultGateway = "116.202.208.65";

  boot.loader.systemd-boot.enable = true;

  users.users.ansible = {
    isNormalUser = true;
    home = "/home/ansible";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAd8nLLjysVefmk3I6BI/IkooUvnGSy7966T54gWNvgW nico@dragons-ryzen"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFHQIfZiaWXzz5bgylkdKzbgGq9ef+74Vdf4fbUZjmVXbQBS25YkA8nblg36PEjjT0qERYvlTQddNmYL7KhQiJidgcnwWAXIJNdne3CU8PFgpNv8I5dD/m9dMI2/C3zNK0uzWYv4H1efnowMr7xzc17dpv8L8KFdGvaghmeTc9CfWbYe2Z8mu3FEuTlTBrak0NDoT6uLA4ppPG8bMKRcpcmpIyiRo1YhCYgQ6bFOhx2rsEE/SMgdrUap4uesIOl6U2GJCv0OqE0CECWQC9sZiVdhvdq4i3w5RRNjfjvjc1F6aC7kE2rbDuZ1D3o5cLAXUetSWCZWcM60AOL6RtTjsKVqkp35aDfHrZfNceKqoa2Re6BivAEPD2w838VMfOi8E21A9QXYS/jXKxK92OCUSTD7KgkdiYXdaUpaJ/E5XZG3S5xcqEOPiqwsRRBJwIpPcA5+9Gz1VkWrUuqzznkIvmRbDiZy3vjY4Wd2K6r8QyB/syMnqM/JhauR7q2PcJzOTUCjy9/yqLOzqqUpPsS+C89IJJNKokIvPtSxEBfQ8Emb3XCfPPuxmfNBy7kj4p08enzKYgoBt0+UOjPltfLblHftj9nokWc/cSgikH56czxJWGp+C4LIPz/QzEpljfwdP9+lfuB5msVlkYAgDEcw+/pDI3La7f7ZRuNiaBZkqAuQ=="
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDnCz5nN5C0ap/Ym7kDR0dAd9oEBqw3TG7dXa47fjQZgBQZfRZbAaD+3yxgsO0ZBg+RGdQDFGo36EGpV9AHv3BEb3OBFrrhSmKX+7F7eJvYb0jw6t6K+PjJUfukXiz80BlrjMS7hsqjfLCyeVZrfTNC7h4aLbW/iVRa6ItrWUrdVOIwofqoKxJUB0sMI9Bdc3KsirMuoD7zV7oA9kUHp+UzsTDV4oPsHa3iQn2R6nlUFUz5zazWVwlsaTP2A+XkSGKMhJFfmSyqkHlpdMDqYMHiKONzjp55wBDBFFUg4We7t/WNSb6R/y6kSHgjeSxJLozPhlbYmZXaRR3AOWVJC7nSm/EUmEVuNzX4JqLko/Ahks1oHkqVThP4Gyaueu7iQat8iqbdmta+6DnkbjzAlowm2zwlerpcV75fQq/KEKte2q3QMK+ip7lKOq9+cEulR9PAYUvqzO6AZobBwfavgoTGa5jeREnlj3VAh6tM4P7htmL2t2RN2Xn7C7m6/JH3ln8="
    ];
  };
  services.openssh.enable = true;
  security.sudo.extraRules = [{
    users = [ "ansible" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
  networking.nameservers = [ "1.1.1.1" ];
  environment.systemPackages = with pkgs; [ python3 git ];
  system.stateVersion = "23.05";

  systemd.tmpfiles.rules = [
    "d /var/garuda 1555 root root"
  ];

  nix.package = (import
    (builtins.fetchTarball
      "https://github.com/nixos/nixpkgs/tarball/nixos-unstable")
    { }).nixFlakes;
}
