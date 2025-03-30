{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      nixpkgs,
      self,
      systems,
    }:
    let
      eachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f
            (import nixpkgs {
              system = system;
              overlays = [ self.overlays.default ];
            }).pkgsCross.armv7l-hf-multiplatform.pkgsStatic
        );
    in
    {
      overlays.default = final: prev: {
        musl = prev.musl.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./time.patch ];
        });
        garage = prev.garage.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./current_thread.patch ];
        });
        atop = prev.atop.overrideAttrs (old: {
          preConfigure = ''
            for f in *.{sh,service}; do
              findutils=${final.findutils} substituteAllInPlace "$f"
            done

            substituteInPlace Makefile --replace 'chown' 'true'
            substituteInPlace Makefile --replace 'chmod 04711' 'chmod 0711'
          '';
        });
        htop = prev.htop.override {
          sensorsSupport = false;
          systemdSupport = false;
        };
        util-linux = prev.util-linux.override {
          ncursesSupport = false;
          pamSupport = false;
        };
      };

      checks = eachSystem (pkgs: {
        inherit (pkgs)
          bandwhich
          bottom
          file
          garage
          gdb
          git
          htop
          lsof
          pv
          strace
          tinyfetch
          tree
          util-linux
          watch
          ;
        inherit (pkgs.buildPackages)
          rustc
          gcc
          ;
      });

      legacyPackages = eachSystem (p: p);
    };
}
