#!/bin/bash
set -x;
# This is a script to be run from /etc/rc.local
# It's purpose is to download and run the installation script for DNASeq
# It always tries to run the installer -- the installer itself will stop
# if it detects that the installation has already been completed

# This script
# 

LOG="/home/ubuntu/.DNASeq.install_log.txt"
INSTALLER="https://raw.githubusercontent.com/DrOppenheimer/Kevin_shell_scripts/master/workscript.sh"
INSTALLER_SCRIPT=`basename $INSTALLER`

# Will only run the installer if the $LOG is not there
if [ ! -f $LOG ]; then  # THERE IS INSTALLER
    cd /home/ubuntu/
    export https_proxy=https://cloud-proxy:3128
    #curl -k $INSTALLER | sudo bash 2>&1 | tee -a $LOG
    wget $INSTALLER
    chmod +x $INSTALLER_SCRIPT
    sudo ./$INSTALLER_SCRIPT 2>&1 | tee -a $LOG
else
    echo "Looks like the installer already ran - delete /home/ubuntu/..DNASeq.install_log.txt and try again."
fi

# if [ ! -f $INSTALLER ]; then  # THERE IS INSTALLER
#     cd /home/ubuntu/
#     export https_proxy=https://cloud-proxy:3128
#     wget https://raw.githubusercontent.com/DrOppenheimer/Kevin_shell_scripts/master/install_DNASeq_pipe.sh
#     chmod +x install_DNASeq_pipe.sh
#     #./install_DNASeq_pipe.sh
#     ./install_DNASeq_pipe.sh 2>&1 | tee -a $LOG
# else
#     cd /home/ubuntu/
#     #./install_DNASeq_pipe.sh
#     ./install_DNASeq_pipe.sh 2>&1 | tee -a $LOG
# fi



