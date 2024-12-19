{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      self,
      rust-overlay,
    }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          self.overlays.default
          rust-overlay.overlays.default
        ];
      };
      armPkgs = pkgs.pkgsCross.armv7l-hf-multiplatform;
    in
    {
      overlays.default = final: prev: {
        musl = prev.musl.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./time.patch ];
        });
      };

      packages.x86_64-linux = {
        inherit (armPkgs.pkgsStatic)
          tinyfetch
          neofetch
          garage
          ncdu
          dust
          syncthing
          helix
          ;
        inherit (armPkgs.pkgsStatic.buildPackages)
          rustc
          gcc
          ;
        garage-dbg = armPkgs.garage.overrideAttrs {
          cargoBuildType = "debug";
          dontStrip = true;
        };
        garage-dyn = pkgs.runCommand "garage-patched" { } ''
          mkdir $out/bin -p
          cp --no-preserve=mode,ownership,timestamps ${pkgs.pkgsCross.armv7l-hf-multiplatform.garage}/bin/garage $out/bin
          patchelf --set-interpreter /lib/ld-linux.so.3 $out/bin/garage
        '';
        cc-dyn = pkgs.pkgsCross.armv7l-hf-multiplatform.stdenv.cc;
      };

      legacyPackages.x86_64-linux = pkgs;
    };
}
