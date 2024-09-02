#!/bin/bash
rand=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13)
git add .
git commit -m "[$random_string]"
git push
#u mean say i m lazy, i would i m smart 

