final: _prev: {
  alertmanager-fcm = final.callPackage ./alertmanager-fcm { };
  garuda-website = final.callPackage ./garuda-website { pkgs = final; };
  garuda-startpage = final.callPackage ./garuda-startpage { pkgs = final; };
}
