#!/bin/bash -x

dot_root="$( cd "$( dirname "$0" )" && pwd )/dot"

function overwrite_with_symlink () {
  src_path=$1
  short_dir=$(dirname "${src_path##*"${dot_root}"/}")
  filename=$(basename "${src_path}")

  mkdir -p "${HOME}/${short_dir}"
  ln -sf "$src_path" "${HOME}/${short_dir}/${filename}"
}

find "$dot_root" -type f -print0 |
    while IFS= read -r -d '' line; do
        overwrite_with_symlink "$line"
    done
