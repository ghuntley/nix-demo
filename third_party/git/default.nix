# Copyright (c) 2025 Geoffrey Huntley <ghuntley@ghuntley.com>. All rights reserved.
# SPDX-License-Identifier: Proprietary

# Custom git with security patches applied
#
# Patches are numbered and named by purpose:
#   001-disable-force-push.patch - Disables git push --force
#   002-disable-force-with-lease-and-plus-refspec.patch - Disables --force-with-lease,
#     +refspec and every other forced ref update (config refspecs, --mirror, send-pack)
#   003-remove-force-push-from-docs.patch - Drops the force options and force-push
#     advice from the man pages (git-push, git-send-pack, config, user-manual, ...)
#   004-hide-force-push-options.patch - Hides -f/--force, --force-with-lease and
#     --force-if-includes from `git push -h` (they are still refused)
#   005-disable-http-push-force.patch - Ignores --force and +ref in git http-push
#     (WebDAV), which skips set_ref_status_for_push and so bypassed 002
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
    ./005-disable-http-push-force.patch
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
