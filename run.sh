#!/bin/bash

. $(dirname $0)/utils.sh

set -e 

if [ $# -ne 2 ] && [ $# -ne 1 ];
then 
	echo_e "Usage: run.sh <P4_PROGRAM_NAME> [<BFRT_PRELOAD_FILE>]"
	exit 1
fi


DIR=`cd $(dirname $0); pwd`
PROGRAM=$1
PORT_INIT_FILE="$DIR/ucli_port_init"

if [ $# -eq 2 ];
then
BFRT_PRELOAD_FILE=`cd $(dirname $2); pwd`/$(basename $2)
fi

echo_i "Find and kill previous process."

$DIR/kill.sh $PROGRAM

sleep 0.1

if [ -n "`pgrep bf_switchd`" ];
then 
    echo_e "Switch is being used by another program."
    exit 1
fi

echo_i "Boot switch in the background."

echo_r "$SDE/run_switchd.sh -p $PROGRAM > /dev/null 2>&1 &"

if [ $# -eq 2 ];
then
echo_i "Initializing tables... "

echo_r "$SDE/run_bfshell.sh -b $BFRT_PRELOAD_FILE > /dev/null 2>&1"

echo_i "Done."
else
echo_w "Skip table initialization."
fi

echo_i "Configuring ports... "

echo_r "$SDE/run_bfshell.sh -f $PORT_INIT_FILE > /dev/null 2>&1"

echo_i "Done."
