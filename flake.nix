{
  description = "devenv container";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix.url = "github:NixOS/nix";
    devenv.url = "github:cachix/devenv/latest";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix,
      devenv,
      ...
    }:
    {
      packages.x86_64-linux.devenv-image =
        let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};

          docker = "${nix}/docker.nix";

          image = import docker {
            inherit pkgs;
            name = "devenv";
            extraPkgs = [ devenv.packages.${system}.devenv ];
            nixConf = {
              "filter-syscalls" = false;
            };
            uid = 1000;
            gid = 100;
            uname = "devenv";
            gname = "users";
            bundleNixpkgs = false;
          };
        in
        image.override { uid = 1001; };
    };
}
