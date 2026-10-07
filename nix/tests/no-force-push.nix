# NixOS VM test: the patched git must refuse force pushes while normal pushes keep working.
# `pkgs` must already have nix/overlay.nix applied; runNixOSTest hands the
# same read-only package set to every node, so the node's `pkgs.git` is the
# patched one.
{ pkgs }:

pkgs.testers.runNixOSTest {
  name = "git-no-force-push";

  nodes.machine = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.git ];
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Prove the VM sees the overlaid package, not stock git.
    assert machine.succeed("readlink -f $(command -v git)").strip().startswith("${pkgs.git}"), "VM is not using the patched git"

    git = "git -c user.name=test -c user.email=test@example.com -c init.defaultBranch=main"

    with subtest("normal push works"):
        machine.succeed(f"{git} init --bare /srv/remote.git")
        machine.succeed(f"{git} clone /srv/remote.git /root/work")
        machine.succeed(f"cd /root/work && echo one > file && {git} add file && {git} commit -m one")
        machine.succeed(f"cd /root/work && {git} push origin HEAD:main")
        original = machine.succeed("git -C /srv/remote.git rev-parse main").strip()

    with subtest("force push is refused"):
        machine.succeed(f"cd /root/work && echo two > file && {git} commit -a --amend -m rewritten")
        for args in ["--force origin HEAD:main", "-f origin HEAD:main",
                     "--force-with-lease origin HEAD:main",
                     "--force-with-lease=main origin HEAD:main",
                     "origin +HEAD:main"]:
            out = machine.fail(f"cd /root/work && {git} push {args} 2>&1")
            assert "is disabled and not allowed" in out, f"unexpected output for `push {args}`: {out}"
        assert machine.succeed("git -C /srv/remote.git rev-parse main").strip() == original, \
            "remote ref changed despite force push being disabled"

    with subtest("forced refspecs from config and --mirror are rejected"):
        machine.fail(f"cd /root/work && {git} -c remote.origin.push=+HEAD:refs/heads/main push origin")
        machine.fail(f"cd /root/work && {git} push --mirror origin")
        machine.fail(f"cd /root/work && {git} send-pack --force /srv/remote.git +HEAD:refs/heads/main")
        assert machine.succeed("git -C /srv/remote.git rev-parse main").strip() == original

    with subtest("non-forced push of rewritten history is rejected by remote"):
        machine.fail(f"cd /root/work && {git} push origin HEAD:main")
        assert machine.succeed("git -C /srv/remote.git rev-parse main").strip() == original
  '';
}
