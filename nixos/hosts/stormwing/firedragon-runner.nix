{
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [ ../../modules ];

  garuda.services.compose-runner.firedragon-runner = {
    source = ../../../compose/firedragon-runner;
  };

  system.stateVersion = "25.05";
}
