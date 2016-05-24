#!/bin/bash
# simple tool to toggle proxy vars on or off

my_proxy="http://cloud-proxy:3128"

if [ -z ${http_proxy+x} ]; then
    echo "setting proxy_vars";
    export http_proxy=$my_proxy;
    export https_proxy=$my_proxy;
    export ftp_proxy=$my_proxy;
else
    echo "unsetting proxy_vars";
    unset http_proxy;
    unset https_proxy;
    unset ftp_proxy;
fi
