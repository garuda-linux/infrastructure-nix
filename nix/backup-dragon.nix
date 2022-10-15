{ ... }: {
  imports = [ ./garuda/garuda.nix ];

  # Base configuration
  networking.hostName = "backup-dragon";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.30";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # LXC support
  boot.loader.initScript.enable = true;
  boot.isContainer = true;
  systemd.enableUnifiedCgroupHierarchy = false;

  # Enable borg repositories
  services.borgbackup.repos = {
    garuda-esxi-cloud = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDeUvPec36guuzUc4eEfUk7qjKgB0y8kVMupIyOuKiU/NOyBWXmxHN+2zsPXCkXcElXtSh67T7IKAuXwt2n8GEtnwsiUsD1fB9v0cG1qRFzQ63KmZyzTTgJeaDtdZ1DlQEoTCimM6gdVraAgskB2E071LDMf2XS7bPV6y/kvmSeTTmoYKz3chzJr18Cp2AnZiFLj2RglCT3NsUF/E3+wrE7IJGXTqsk4SDenS48WkrCpe4az4yiBqx/J1JdkCll9PIHG/jfa9IzI6HJ/Ru1j1Wum7jAywsPmObnWxpsC4651EYrDAuiAOMWXJnnfxBhYkO83j22BPohNfw9NO7XdbRYXoHPFDhTOzwnGEu0+7lassOEsNadNHJhIMATHOy+iD35pgnHu47BpiU/xvqwbXNp6WYlScISlQDHT8/86DCWAnDqTvR8EiFPTKh20efKCtHbgwoumiiPUClP/jiWHX59lK48neFfKl1vwh8BgEHJ1KNBBKAO1ntvMs97nIJXAGc= root@garuda-esxi-cloud"
      ];
      path = "/backups/esxi-cloud";
    };
    garuda-esxi-web = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCrSymW+hDX7ZQZI2NOL8XpEoM3ogq+ug1iu/IAHkuOGChuyAXtGa7d204kkGYWbePJcZlKkSj7ntMayoIuUyhsNKuDB2Ud3dpml3kol3P67OR0WkiFzZOjjvQ3AldlLGu2UAzIOiQ0GhUsd0nTJBmFRaNyMHMlxUY2v/lS0bfaqfC4m+sm3EzZ3RSnTGisT+944T6OdpcI4d6EkvFeZeGF6I797EjDyfmLd+EG4apqusXbuYOp07h+7ZswI9z767eYXVzd6rARkThuSUAxcskUYgRUWJ873XrgXyuz0eogONGfKOcEiz7/rB1lQ/4S7A2Vf92nAi7j8B6cDm4RoiQrGiLKcMkJZ2IbZRaRyXOJ+3/0tqLht0aGg94hHXBJWr7jFICfmLQrztetS9/DlxtLXrodFQTOnBCBWW+ukIuyTKEvyyhkm+s/2ZoUi4obi780OLYQoShjohYPrlNRkJ+1rhRffMIjesa++wjyRiMH7LhFr275E+rZZuaWkZvzv2E= root@garuda-esxi-web"
      ];
      path = "/backups/esxi-web";
    };
    garuda-esxi-forum = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDnxah3M4jMXIXkWl7YHbMk10Gp1Xw6usD345VNKWu1MHy6XIVHOUeqcLzGsqZdM2Xav1VldoMQgLVKzdeFKN8OQQ0n8UcMgDzCjnzDxE9GQQ+6k9pAJeMMnPKHJY0w2j+KpZFl62/AlOKDw1um1DyIMayHk0Va257sIMYiwgjMkToqMq/cP3VRAWqAtq1cms9h6b0hEo3HnxOdAzn+zR2gqpXGBAxdGXhIY3z82bkwGQgd0YTj9nnRY/Tlc6TaDG9qE2KfQXMQLlWWN3RCQF65XqyHgSgRjYdqt5l3ug0RSdUnHcA6QSytzOsEDYrGrNdsDHUEblAZC/We3JPi3ORRbdpiH2t5XhlqKSI8KgKMkClWU1rThRsnkFryx65QCjKo8whs/M+3CyxFMwOb+YMfegPrT/c8jZucPvtnPCnbiWzELApqCPe3JJhNRH/g62JGWrvQUE/eRqJEuEEOMOgk7mDG2IASf9NpaYfDQdzVXctXcv+TzK0PnhupWmqQhss= root@esxi-forum"
      ];
      path = "/backups/esxi-forum";
    };
    garuda-esxi-web-two = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0jbpVPeiKjIk53UeHkJ1SYlC9qAYAIB302ONyRfGuO/aJIOk1IZk/aMIJtKe9KwVZSXQLqk90gYV3Eqt1ky2YahDlXiquKlp7bjvRxUIPklZGQrmwi78T37LSLD1ki1i5RlJNlcDoHOEDvBLV9ObQecjZj+FgFeQQ7GRODC/8jI7hdouNSkoi7SfF7kN9+oxW9CraXflwnDQi66tIAJeyDDGI+1/CeqL9z6mc+5M6Le5kdfjPxTrqG3VoNwU31MXiIFQ5TZsAPirgT7p6Ri7bxBzoe3jXMJcymXddhvUq1uqHpPzsJKZgbbDK1lKp7Bo0N1o+TeGCpU7KAMAg8zg509MVHN2bVCPkk4/1vXuD/EjWmQnaMpeBAIFMtqrDm3BjfIB98x2SfxVWh62URHyP0bdz46o6ZK8HulLjelUVj8D3AvLTHDR9IWHdToILMJ7ToAfkFpzN5g1ewXs0pRA9yZzViT8dG7ByEYcGHPhYh7mogjOKMtw1om0aqyNoTZ8= root@esxi-web-two"
      ];
      path = "/backups/esxi-web-two";
    };
    garuda-web = {
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDgnm1gR2LdhlGH36tsQKyS/mYEOlv8KA3YeczJTVpKpPWWHZFvGX+4PlhG88ka0Dtu+TQ0Q2FhARYb6qafgFOWtvY1oYIRPtyRczyptk2geruP7kFsI1HWUw3YqzsmhwwWyUBbdnzfTj7I5AfxM6JL9LcCtnRJb66hm/peT4jOg1GAzzuSnuz+7ZO7UXfjuSuHQ8zv1YIp6U2MvHKq9JztKfTbRYHFU/9XQfm1atgdS/G9isTc2LO23ZH++3ULgZxQtYnvekkTEwI23ko7MA+VPP5gdnAOP1jmqDo8sMTuNlo7CPn4OHOYgS5fuWpln4G/b/MZxthGo08/k3rairDX2398ZJzBtBtKZBI8pR+tHYwlNgZ3fa4wjyEUTx8f2T8LruszNgQj5OLApGjyvhuNubQFps+ur1lauDJm6mr1YVGKfHXg+NzU1jiuGcHERNVE4rlzYc23vJVdIyhBHIQm9Al6VWOdbpUGDH7ztX94o36WKsJ9/dT70DR+wwf+y+0= root@garuda-web"
      ];
      path = "/backups/web";
    };
  };

  # Allow access for SGS to check for offsite backups and prune status
  users.users.sgs = {
    isNormalUser = true;
    home = "/home/sgs";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxBY8TX0iEQkf3Bym+3XVlrk8OLOwHOrj7Uy+WxjncOkkutyZ1WsY9liF4j9yjptyQG7Lx8OM8q44NE6+Rk1OXJXMF7CZ4Jq/WvMVnh2zKyNnF8wHBcspsAdG90wCxo6OmNpnY/rRRlNwwnore7raF2PrERtSlsEvLsUgvspYQ8cnLwerJP43QeETlpE1oR0FrbXWQet0I63Ky6UDEp07x0yee21VHnAG74rjGeFGwJBmCPSxnfGVNhCaR0zyu9+hh222liBrlilYm8nqLlsYGZCXiVdOxXJbBy89EVpHds7Lutf+TAYwsPGZf7U4k+g2Jx8N0JHXyzVZa0zS+I48+tqBBflEOqU9oEfGuz4cU/qWys5soLcRX2p9td+RF3OEdBKlTW4UYsINJUri6QSEUrsGaXqQZy8Ds2FBdUpb4pmFVlo9+4qRouiI80a5xVa7a1E5eS5xK5BzWH4fNg5SqtT5L9i2i1ocZp7FA0oa+ixnXNiC1umPZaY/9s+5fh1s= sgs-linux@shell.sf.net"
    ];
  };

  system.stateVersion = "22.05";
}
