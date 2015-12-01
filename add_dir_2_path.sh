#!/bin/bash
# simple script to add any directory to PATH
my_path=`pwd`;
# add to current path
export PATH=$PATH:$my_path;
# add to .profile to be added to the PATH when new session is started
sudo echo export PATH=$PATH:$my_path >> ~/.profile;
# print complete message
echo "Old PATH:"
echo $PATH;
echo "Adding this to PATH:"
echo $my_path;
echo "New PATH:"
echo $PATH;
