#!/bin/bash

. $(dirname $0)/utils.sh

config_file="$SDE_INSTALL/share/p4/targets/tofino/$1.conf"
install_dir="$SDE_INSTALL/share/tofinopd/$1"

remote_sde_install=$(ssh $2 'echo $SDE_INSTALL')

if ! [ -f "$config_file" ]; then
    echo_e "Can not found installed file"
    exit 1
fi

scp $config_file $2:$remote_sde_install/share/p4/targets/tofino/
scp -r $install_dir $2:$remote_sde_install/share/tofinopd/