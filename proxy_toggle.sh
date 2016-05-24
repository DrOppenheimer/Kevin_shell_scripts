#!/bin/bash
# simple tool to toggle proxy vars on or off
if [ -v ${http_proxy+x} ]; then
    echo "unsetting proxy_vars";
    . ~/git/unset_proxy;
else
    echo "setting proxy_vars";
    . ~/git/set_proxy;
fi
# http://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
# if [ -z ${var+x} ]; then echo "var is unset"; else echo "var is set to '$var'"; fi
