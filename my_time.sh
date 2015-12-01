#!/bin/bash
# simple script to display real time;
negative_hour_offset=6;
date --date "$negative_hour_offset hours ago" +%Y-%m-%d:%H:%M:%S;
