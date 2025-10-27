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
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          docker = "${nix}/docker.nix";

          devenvCli = devenv.packages.${system}.devenv;

          image = import docker {
            inherit pkgs;

            name = "devenv";

            Labels = {
              "org.opencontainers.image.title" = "devenv-image";
              "org.opencontainers.image.source" = "https://github.com/sandydoo/devenv-image";
              "org.opencontainers.image.vendor" = "Cachix";
              "org.opencontainers.image.version" = devenvCli.version;
              "org.opencontainers.image.description" = "devenv container image";
            };

            # Set up non-root user
            uid = 1000;
            gid = 100;
            uname = "devenv";
            gname = "users";

            nixConf = {
              filter-syscalls = false;
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              auto-optimise-store = true;
            };

            # Add devenv
            extraPkgs = [ devenvCli ];

            # Don't bundle Nix to reduce the image size
            bundleNixpkgs = false;

            # Remove unneeded tools or reduce their closure size
            coreutils-full = pkgs.busybox;
            curl = pkgs.emptyDirectory;
            gnutar = pkgs.emptyDirectory;
            gzip = pkgs.emptyDirectory;
            gitMinimal =
              (pkgs.git.override {
                perlSupport = false;
                pythonSupport = false;
                withManual = false;
                withpcre2 = false;
              }).overrideAttrs
                (_: {
                  doInstallCheck = false;
                });
            openssh = pkgs.emptyDirectory;
            wget = pkgs.emptyDirectory;
          };
        in
        { devenv-image = image; }
      );
    };
}
