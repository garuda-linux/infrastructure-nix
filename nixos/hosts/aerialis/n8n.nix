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
        N8N_PUBLIC_API_DISABLED = true;
        N8N_PUBLIC_API_SWAGGERUI_DISABLED = true;
        N8N_DIAGNOSTICS_ENABLED = false;
        N8N_VERSION_NOTIFICATIONS_ENABLED = false;
        N8N_TEMPLATES_ENABLED = false;
    };
    openFirewall = true;
  };

  system.stateVersion = "25.11";
}
