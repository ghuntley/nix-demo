{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # git with `push --force` disabled (see third_party/git)
  overlays = [ (import ./nix/overlay.nix) ];

  # https://devenv.sh/packages/
  packages = [ pkgs.git ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    hello         # Run scripts directly
    git --version # Use packages
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"

    set -euo pipefail
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    g() { git -c user.name=test -c user.email=test@example.com -c init.defaultBranch=main "$@"; }

    g init -q --bare "$tmp/remote.git"
    g clone -q "$tmp/remote.git" "$tmp/work" 2>/dev/null
    cd "$tmp/work"
    echo one > file && g add file && g commit -qm one
    g push -q origin HEAD:main
    echo two > file && g commit -qa --amend -m rewritten

    for args in "--force origin HEAD:main" "-f origin HEAD:main" \
                "--force-with-lease origin HEAD:main" "origin +HEAD:main"; do
      # shellcheck disable=SC2086
      if out=$(g push $args 2>&1); then
        echo "FAIL: git push $args succeeded"; exit 1
      fi
      echo "$out" | grep -q "is disabled and not allowed" || { echo "FAIL: unexpected output: $out"; exit 1; }
      echo "ok: git push $args refused"
    done

    if g -c remote.origin.push=+HEAD:refs/heads/main push origin 2>/dev/null; then
      echo "FAIL: +refspec from config force-pushed"; exit 1
    fi
    echo "ok: +refspec from config refused"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
