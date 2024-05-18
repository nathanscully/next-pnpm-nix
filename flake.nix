{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fetchPnpmDeps.url = "github:scrumplex/nixpkgs/pkgs/build-support/fetchPnpmDeps";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      fetchPnpmDeps,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlay = final: prev: {
          # Inherit the changes into the overlay
          inherit (fetchPnpmDeps.legacyPackages.${system}) pnpm;
        };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };

        next-app = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "next-app";
          name = "next-app";
          src = ./.;
          version = "1.0.0";
          pnpmDeps = pkgs.pnpm.fetchDeps {
            inherit (finalAttrs) pname version src;
            hash = "sha256-j2FEwvpRlvAPvupsHrYJjgwyVQVI5a/6Pjn/k/fD2cY=";
          };
          nativeBuildInputs = [
            pkgs.nodejs
            pkgs.pnpm.configHook
          ];
          doCheck = false;
          postBuild = ''
            pnpm run build
          '';
          installPhase = ''
            cp -r .next/standalone/ $out
            cp -r public $out/public
            cp -r .next/static $out/.next/static
          '';
        });
      in
      # pnpm --offline --frozen-lockfile --ignore-script --prod deploy next-app-deploy
      with pkgs;
      rec {
        packages = {
          inherit next-app;
          default = next-app;
        };
        # Development environment
        devShell = mkShell {
          name = "next-pnpm-nix";
          nativeBuildInputs = [
            nodejs
            typescript
            pnpm
          ];
        };
      }
    );
}
