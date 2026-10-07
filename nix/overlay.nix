# Overlay replacing git with a build that refuses `git push --force`.
final: prev: {
  git = import ../third_party/git { inherit (prev) git; };
  gitFull = import ../third_party/git { git = prev.gitFull; };

  # nixpkgs derives gitMinimal from the final `git`, and gitMinimal is used at
  # build time all over nixpkgs (hatch-vcs -> python -> llvm -> rustc, ...).
  # Rebuild it from the unpatched git, with the same arguments nixpkgs uses,
  # so the overlay doesn't trigger a world rebuild. Users only get the patched git.
  gitMinimal = prev.git.override {
    withManual = false;
    osxkeychainSupport = false;
    pythonSupport = false;
    perlSupport = false;
    rustSupport = false;
    withpcre2 = false;
    curl = if prev.stdenv.hostPlatform.isFreeBSD then prev.curlMinimal else prev.curl;
  };
}
