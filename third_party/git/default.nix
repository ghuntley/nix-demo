# Copyright (c) 2025 Geoffrey Huntley <ghuntley@ghuntley.com>. All rights reserved.
# SPDX-License-Identifier: Proprietary

# Custom git with security patches applied
#
# Patches are numbered and named by purpose:
#   001-disable-force-push.patch - Disables git push --force
#   002-disable-force-with-lease-and-plus-refspec.patch - Disables --force-with-lease,
#     +refspec and every other forced ref update (config refspecs, --mirror, send-pack)
#
# Usage in overlay:
#   git = import ../third_party/git { inherit (prev) git; };
#   gitFull = import ../third_party/git { git = prev.gitFull; };

{ git }:

let
  customPatches = [
    ./001-disable-force-push.patch
    ./002-disable-force-with-lease-and-plus-refspec.patch
  ];
  patchNames = map baseNameOf customPatches;
  existingPatchNames = map baseNameOf (git.patches or []);
  # Only add patches that aren't already applied (prevents double-patching in git-with-svn)
  newPatches = builtins.filter (p: !(builtins.elem (baseNameOf p) existingPatchNames)) customPatches;
in
git.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or []) ++ newPatches;
  doCheck = false;
  doInstallCheck = false;
})
