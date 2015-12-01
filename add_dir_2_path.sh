#!/bin/bash
# simple script to add any directory to PATH
my_path=`pwd`
# add to current path
PATH=$PATH:$my_path
# add to .profile to be added to the PATH when new session is started
sudo echo PATH=$PATH:$my_path >> ~/.profile
# print complete message
echo "Adding this to PATH:"
echo "$my_path"
