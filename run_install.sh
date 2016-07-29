#!/bin/bash

export https_proxy=https://cloud-proxy:3128
curl -k https://raw.githubusercontent.com/DrOppenheimer/Kevin_shell_scripts/master/workscript.sh | bash
