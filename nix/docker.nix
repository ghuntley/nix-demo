# OCI/Docker image shipping the patched git.
{ pkgs }:

pkgs.dockerTools.buildLayeredImage {
  name = "git-no-force-push";
  tag = "latest";
  contents = with pkgs; [ git bashInteractive coreutils cacert ];
  extraCommands = ''
    mkdir -p tmp work
    chmod 1777 tmp
  '';
  config = {
    Entrypoint = [ "${pkgs.git}/bin/git" ];
    WorkingDir = "/work";
    Env = [
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "HOME=/tmp"
    ];
  };
}
