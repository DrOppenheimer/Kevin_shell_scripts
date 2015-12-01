#!/bin/bash
# simple script to add any directory to PATH
# print current path
echo "Old PATH:";
echo $PATH;
# get current dir
my_path=`pwd`;
# add to current path
# export PATH=$PATH:$my_path;
# add to .profile to be added to the PATH when new session is started
echo "export PATH=$my_path:$PATH" >> ~/.profile;
# source ~/.profile to update PATH in current session
source ~/.profile;
# print complete message
echo "Adding this to PATH:";
echo $my_path;
echo "New PATH:";
echo $PATH;
