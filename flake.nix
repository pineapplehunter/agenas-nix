{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      nixpkgs,
      self,
      systems,
    }:
    let
      inherit (nixpkgs) lib;
      eachSystem = lib.genAttrs (import systems);
      pkgsFor =
        system:
        import nixpkgs {
          system = system;
          overlays = [ self.overlays.default ];
        };
      armStaticPkgsWith = pkgs: pkgs.pkgsCross.armv7l-hf-multiplatform.pkgsStatic;
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
      };

      checks = eachSystem (
        system:
        let
          p = self.legacyPackages.${system};
        in
        {
          inherit (p)
            garage
            git
            tree
            ;
          htop = p.htop.override {
            sensorsSupport = false;
            systemdSupport = false;
          };
          util-linux = p.util-linux.override {
            ncursesSupport = false;
            pamSupport = false;
          };
          inherit (self.legacyPackages.${system}.buildPackages)
            rustc
            gcc
            ;
        }
      );

      legacyPackages = eachSystem (system: armStaticPkgsWith (pkgsFor system));
    };
}
