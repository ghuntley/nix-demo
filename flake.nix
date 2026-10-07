{
  description = "git with force push disabled: overlay, NixOS VM test and Docker image";

  inputs.nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      }));
    in
    {
      overlays.default = import ./nix/overlay.nix;

      packages = forAllSystems (pkgs: {
        inherit (pkgs) git gitFull;
        dockerImage = import ./nix/docker.nix { inherit pkgs; };
        default = pkgs.git;
      });

      checks = forAllSystems (pkgs: {
        git = pkgs.git;
        no-force-push = import ./nix/tests/no-force-push.nix { inherit pkgs; };
      });
    };
}
