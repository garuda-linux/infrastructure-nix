{ ... }: {
  imports = [ ./garuda/garuda.nix ];

  # Base configuration
  networking.hostName = "backup-dragon";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.70";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # LXC support
  boot.loader.initScript.enable = true;
  boot.isContainer = true;
  systemd.enableUnifiedCgroupHierarchy = false;

  # Enable borg repositories
  services.borgbackup.repos = {
    esxi-web = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDNY3T1S+bknnfCpBKRtq+j40qFkmhpCBMRd9XkqsEXIaOhRyFLp69S+POOxRETFA5ai5N1Sx/IMCbJ1r3xrU85U6a4qXi84jwlmvVNAjbMWXA+yAV5kYmV2WwHezOL0i0O8Qz9SBH4NYqBRvJqZpETt/cF8Ykt65mOMxg9JR3GFlkbcgOmw1oRzzCTZkvSw7jrleeRmLdRd++ujOfcwzcUngSDKktesRcPuzxjIIX3Mz2HH0246Ot8zqXFwIpl0A1Z6lE7baYRdqmPw6J80kWtxCmDkSKeWRS6tX7HKViIMAlS63+lSU7/KakLISTO0P6qXiX39KC0EJX04iAA6Y1MXbSafTjxl55vASZTAYsZh34FMlT58qBhhgi8lVvK3SkJm8vOHNhpny5WPZbAjao7IdWmzCKZusvpyAnSDU05NM4YZPNgXyITDQjIX8w0HVykrommgZyP6wg/fwvBHyoC0SEMCyAndXeG2dLLJmsvSJbp+I5KPTWIhePRkMi8A2c="
      ];
      path = "/backups/esxi-web";
    };
    web-dragon = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDK+o9S0fmC5zqV24hVgOWKmDVW18S/FTaIGnLtHFF5dHgGmwCsyv/ERFfG5cHv7obMNWV5mrHXIHMTEvowO1r0RzWWy8gMwfoQkhXvohXdMMZXy7jslnYfYWuLxCV//ZvL+0jy6Q8Sidi/yA49jTYYf4pO86lgxKTXTWS/aIXwRn7UY+CDA1u0T6RtonwGwx18hHkMhqb1QgyFpSgT9bgZO7tfaOwr3KvPwk3XbCozYUsPKLKmDXayIivdGPedDWRmJrZd2rUBDVHGHMFvGv8si1xGTCp7ockTsXKLfOVVeiCv6pV2/Nn/Ky0jvrGeLQmqchzK/NkBsLymsH2TX+XmiyEzm1fwtSWG4zG659R0wphzo+g4jMWIqyVb7x2kRTTY2lDC6r5dhWkSemhSI/J5t96mr03cpT14qpVRE8YjL1VqMuw5d6yq++OMF7o183xD3e3s3E2OzY/3DyDtAA5tWKlVg2dNAiO+1YZsDaoLGn5GQeGXgLBjCM2AzPRma+E="
      ];
      path = "/backups/web-dragon";
    };
    sgs-artwork = {
      allowSubRepos = true;
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxBY8TX0iEQkf3Bym+3XVlrk8OLOwHOrj7Uy+WxjncOkkutyZ1WsY9liF4j9yjptyQG7Lx8OM8q44NE6+Rk1OXJXMF7CZ4Jq/WvMVnh2zKyNnF8wHBcspsAdG90wCxo6OmNpnY/rRRlNwwnore7raF2PrERtSlsEvLsUgvspYQ8cnLwerJP43QeETlpE1oR0FrbXWQet0I63Ky6UDEp07x0yee21VHnAG74rjGeFGwJBmCPSxnfGVNhCaR0zyu9+hh222liBrlilYm8nqLlsYGZCXiVdOxXJbBy89EVpHds7Lutf+TAYwsPGZf7U4k+g2Jx8N0JHXyzVZa0zS+I48+tqBBflEOqU9oEfGuz4cU/qWys5soLcRX2p9td+RF3OEdBKlTW4UYsINJUri6QSEUrsGaXqQZy8Ds2FBdUpb4pmFVlo9+4qRouiI80a5xVa7a1E5eS5xK5BzWH4fNg5SqtT5L9i2i1ocZp7FA0oa+ixnXNiC1umPZaY/9s+5fh1s="
      ];
      path = "/backups/sgs-artwork";
    };
  };

  system.stateVersion = "22.05";
}
