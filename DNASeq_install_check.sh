#!/bin/bash

# This is a script to be run from /etc/rc.local
# It's purpose is to download and run the installation script for DNASeq
# It always tries to run the installer -- the installer itself will stop
# if it detects that the installation has already been completed

INSTALLER="/home/ubuntu/install_DNASeq_pipe.sh"

if [ ! -f $LOG ]; then  # THERE IS INSTALLER
    wget 
    



