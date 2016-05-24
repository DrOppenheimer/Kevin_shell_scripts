#!/bin/bash
# simple tool to toggle proxy vars on or off

my_proxy="http://cloud-proxy:3128"

if [ -v ${http_proxy+x} ]; then
    echo "unsetting proxy_vars";
    unset http_proxy;
    unset https_proxy;
    unset ftp_proxy;
else
    echo "setting proxy_vars";
    export http_proxy=$my_proxy;
    export https_proxy=$my_proxy;
    export ftp_proxy=$my_proxy;
fi

# http://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
# if [ -z ${var+x} ]; then echo "var is unset"; else echo "var is set to '$var'"; fi
