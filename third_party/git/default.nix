# Copyright (c) 2025 Geoffrey Huntley <ghuntley@ghuntley.com>. All rights reserved.
# SPDX-License-Identifier: Proprietary

# Custom git with security patches applied
#
# Patches are numbered and named by purpose:
#   001-disable-force-push.patch - Disables git push --force
#   002-disable-force-with-lease-and-plus-refspec.patch - Disables --force-with-lease,
#     +refspec and every other forced ref update (config refspecs, --mirror, send-pack)
#   003-remove-force-push-from-docs.patch - Drops the force options from the
#     git-push, git-send-pack and push.* config man pages to match 001/002
#   004-hide-force-push-options.patch - Hides -f/--force, --force-with-lease and
#     --force-if-includes from `git push -h` (they are still refused)
#
# Usage in overlay:
#   git = import ../third_party/git { inherit (prev) git; };
#   gitFull = import ../third_party/git { git = prev.gitFull; };

{ git }:

let
  customPatches = [
    ./001-disable-force-push.patch
    ./002-disable-force-with-lease-and-plus-refspec.patch
    ./003-remove-force-push-from-docs.patch
    ./004-hide-force-push-options.patch
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
