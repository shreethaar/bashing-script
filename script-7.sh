#!/bin/bash

user=$(whoami)
hostname=$(hostname)
directory=$(pwd)
echo "User=[$user] Host=[$hostname] Working dir=[$directory]"
echo "Contents:"
ls
