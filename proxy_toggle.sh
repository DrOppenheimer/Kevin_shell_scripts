#!/bin/bash
# simple tool to toggle proxy vars on or off
if [[ -v $http_proxy ]]; then
    echo "unsetting proxy_vars";
    source ~/git/Kevin_shell_scripts/unset_proxy.sh;
else
    echo "setting proxy_vars";
    source ~/git/Kevin_shell_scripts/set_proxy.sh;
fi
# http://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
# if [ -z ${var+x} ]; then echo "var is unset"; else echo "var is set to '$var'"; fi


# function noproxy
# {
#     /usr/local/sbin/noproxy  #turn off proxy server
#     unset http_proxy HTTP_PROXY https_proxy HTTPs_PROXY
# }


# # Proxy
# function setproxy
# {
#     sh /usr/local/sbin/proxyon  #turn on proxy server 
#     http_proxy=http://127.0.0.1:8118/
#     HTTP_PROXY=$http_proxy
#     https_proxy=$http_proxy
#     HTTPS_PROXY=$https_proxy
#     export http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
# }



