#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

scp -rp techdufus@home.io:/opt/heimdall/* $SCRIPT_DIR/../files/

rm -rf $SCRIPT_DIR/../files/log
