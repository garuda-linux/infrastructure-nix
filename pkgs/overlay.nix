final: _prev: {
  garuda-website = final.callPackage ./garuda-website { pkgs = final; };
  garuda-startpage = final.callPackage ./garuda-startpage { pkgs = final; };
}
