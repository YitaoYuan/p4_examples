#!/bin/bash

path=$(realpath $(dirname $0))
p4_basename=$(basename $1)
p4_name=${p4_basename%.p4}
$path/compile.sh "$1" "$2" 
$path/remote_install.sh "$p4_name" "$3"

