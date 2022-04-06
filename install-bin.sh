#!/bin/bash

bin_root="$( cd "$( dirname "$0" )" && pwd )/bin"

function overwrite_with_symlink () {
  src_path=$1
  short_dir=$(dirname "${src_path##*${bin_root}/}")
  filename=$(basename "${src_path}")

  mkdir -p "${HOME}/bin/${short_dir}"
  ln -s "$src_path" "${HOME}/bin/${short_dir}/${filename}"
}

find "$bin_root" -type f -print0 |
    while IFS= read -r -d '' line; do
        overwrite_with_symlink "$line"
    done
