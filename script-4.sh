#!/bin/bash
# Define bash global variables
# This variable is global and can be used everywhere in this bash script

VAR="global variable"

function bash {
# Define bash local variable
# This variable is local to bash function only
local VAR="local variable"
echo $VAR
}

echo $VAR
bash
# Note the bash global variable did not change
# "local" is the bash reserved word
echo $VAR


