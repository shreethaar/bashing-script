#!/bin/bash

echo for loops
for i in 1 2 3 4 5; do 
    echo Index=[$i]
done

for i in {1..5}; do 
    echo Index=[$i]
done

for(( i=1; i<=5; i++ ))
do 
    echo Index=[$i]
done


