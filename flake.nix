{
  description = "devenv container";

  inputs = {
    nixpkgs.follows = "devenv/nixpkgs";
    nix.url = "github:NixOS/nix";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    devenv.url = "github:cachix/devenv/latest";
  };

  nixConfig = {
    "extra-substituters" = [
      "https://cachix.cachix.org"
      "https://devenv.cachix.org"
    ];
    "extra-trusted-public-keys" = [
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
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
              filter-syscalls = false;
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              auto-optimise-store = true;
            };
            uid = 1000;
            gid = 100;
            uname = "devenv";
            gname = "users";
            bundleNixpkgs = false;
            gitMinimal =
              (pkgs.git.override {
                perlSupport = false;
                pythonSupport = false;
                withManual = false;
                withpcre2 = false;
              }
            ).overrideAttrs (_: { doInstallCheck = false; });
          };
        in
        image;
    };
}
