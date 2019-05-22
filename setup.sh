#!/bin/bash

shopt -s dotglob # consider dot files (turn on dot files)
curr_dir=`pwd`

for file in "${curr_dir}"/setting_files/*
do
  filename=$(basename $file)
  echo "$filename"
  rm -rf "${HOME}/${filename}"
  ln -sf "${curr_dir}/setting_files/${filename}" "${HOME}/${filename}"
done
