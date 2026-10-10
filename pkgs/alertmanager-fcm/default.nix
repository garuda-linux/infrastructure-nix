{ writers, python3Packages }:
writers.writePython3Bin "alertmanager-fcm" {
  libraries = with python3Packages; [
    google-auth
    requests
  ];
  # Long docstring lines are intentional
  flakeIgnore = [ "E501" ];
} (builtins.readFile ./alertmanager-fcm.py)
