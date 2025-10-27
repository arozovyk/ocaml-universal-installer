(**************************************************************************)
(*                                                                        *)
(*    Copyright 2025 OCamlPro                                             *)
(*                                                                        *)
(*  All rights reserved. This file is distributed under the terms of the  *)
(*  GNU Lesser General Public License version 2.1, with the special       *)
(*  exception on linking described in the file LICENSE.                   *)
(*                                                                        *)
(**************************************************************************)

(** Generate postinstall script content for macOS .pkg installers.

    The postinstall script:
    - Creates symlinks from the .app bundle binaries to /usr/local/bin
    - Installs manpages from the .app bundle to /usr/local/share/man
*)
val generate_postinstall_script :
  app_name:string ->
  binary_name:string ->
  string

(** Save postinstall script to the scripts directory with executable permissions. *)
val save_postinstall_script :
  content:string ->
  scripts_dir:OpamFilename.Dir.t ->
  OpamFilename.t
