#!/bin/sh

# Author: Kieran Bingham https://github.com/kbingham
# Source: https://gist.github.com/kbingham/be28a67831c26158bdb4ab2a48e707d4

# Requires 'media-ctl' to parse the media devices
# Requires 'dot' to generate the media-graph png files.

# Identify all V4L2 devices
for v in /sys/class/video4linux/{v4l,video}*;
  do
    vn=`basename $v`
    name=`cat $v/name`
    echo $vn: $name
  done | sort -V;

# Identify all Media Devices
for m in /sys/bus/media/devices/media*;
  do
    mn=`basename $m`
    model=`cat $m/model`
    echo $mn: $model
  done | sort -V;

# Print all media graphs
for d in /dev/media*
  do
    dev=`basename $d`
    echo "$d:"
    media-ctl -p -d $d
    echo ""
    media-ctl -d $d --print-dot | dot -Tpng > $dev-graph.png
  done