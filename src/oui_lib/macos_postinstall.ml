(**************************************************************************)
(*                                                                        *)
(*    Copyright 2025 OCamlPro                                             *)
(*                                                                        *)
(*  All rights reserved. This file is distributed under the terms of the  *)
(*  GNU Lesser General Public License version 2.1, with the special       *)
(*  exception on linking described in the file LICENSE.                   *)
(*                                                                        *)
(**************************************************************************)

let generate_postinstall_script ~app_name ~binary_name =
  Printf.sprintf {|#!/bin/bash
mkdir -p /usr/local/bin

# Create wrapper script instead of symlink to preserve plugin path resolution
cat > "/usr/local/bin/%s" << 'WRAPPER_EOF'
#!/bin/bash
exec "/Applications/%s.app/Contents/MacOS/%s" "$@"
WRAPPER_EOF
chmod +x "/usr/local/bin/%s"

if [ -d "/Applications/%s.app/Contents/Resources/man" ]; then
  mkdir -p /usr/local/share/man
  for section_dir in /Applications/%s.app/Contents/Resources/man/*; do
    if [ -d "$section_dir" ]; then
      section=$(basename "$section_dir")
      mkdir -p /usr/local/share/man/${section}
      for manpage in "$section_dir"/*; do
        [ -f "$manpage" ] && ln -sf "$manpage" "/usr/local/share/man/${section}/$(basename "$manpage")"
      done
    fi
  done
fi
exit 0
|}
    binary_name app_name binary_name binary_name app_name app_name

let save_postinstall_script ~content ~scripts_dir =
  OpamFilename.mkdir scripts_dir;
  let script_path = OpamFilename.Op.(scripts_dir // "postinstall") in
  OpamFilename.write script_path content;
  System.call_unit System.Chmod (755, script_path);
  OpamConsole.msg "Created postinstall script: %s\n"
    (OpamFilename.to_string script_path);
  script_path
