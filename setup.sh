#!/bin/bash

shopt -s dotglob # consider dot files (turn on dot files)
curr_dir=`pwd`

for file in "${curr_dir}"/setting_files/*
do
  echo "$file"
  ln -sf "$file" ~/
done
