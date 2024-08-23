#! /bin/bash

echo "Starting task 1..."
sleep 5 & # simulate a long-running task with sleep

echo "Starting task 2..."
sleep 3 &

wait # wait for all background task to complete

echo "All tasks are complete"


