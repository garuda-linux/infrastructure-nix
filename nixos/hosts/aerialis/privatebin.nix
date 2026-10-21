{
  garuda-lib,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [
    ../../modules
  ];

  garuda = garuda-lib.mkMonitoring {
    host = "aerialis";
    units = [
      "nginx.service"
      "phpfpm-privatebin.service"
    ];
  };

  services.privatebin = {
    enable = true;
    enableNginx = true;
    virtualHost = "bin.garudalinux.org";
    settings = {
      main = {
        name = "Garuda's PrivateBin";
        basepath = "bin.garudalinux.org";
        discussion = true;
        opendiscussion = false;
        password = true;
        fileupload = false;
        burnafterreadingselected = false;
        defaultformatter = "plaintext";
        sizelimit = 10485760;
        template = "bootstrap5";
        languageselection = false;
        qrcode = true;
      };
      # expire_options and formatter_options are left at PrivateBin's defaults, since
      # Nix sorts attribute names and would scramble the order of the dropdowns
      expire.default = "never";
      traffic.limit = 10;
      purge = {
        limit = 300;
        batchsize = 10;
      };
    };
  };

  system.stateVersion = "26.11";
}
