{
  config,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [
    ../../modules
  ];

  services.n8n = {
    enable = true;
    environment = {
        N8N_PORT = "5678";
        N8N_PROXY_HOPS = "1";
        N8N_HOST = "n8n.garudalinux.net";
        N8N_EDITOR_BASE_URL = "https://n8n.garudalinux.net";
        WEBHOOK_URL = "https://n8n-webhooks.garudalinux.net";
    };
    openFirewall = true;
  };

  system.stateVersion = "25.11";
}
