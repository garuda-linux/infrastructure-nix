{
  inputs,
  ...
}:
{
  config.nixpkgs.overlays = [
    (final: prev: {
      garuda-website = final.callPackage ./garuda-website {
        pkgs = final;
        src = inputs.src-garuda-website;
      };
      garuda-startpage = final.callPackage ./garuda-startpage {
        pkgs = final;
        src = inputs.src-garuda-startpage;
      };
    })
  ];
}
