#!/bin/bash

directories=("./obj" "./Linux.x64.Debug" "./Linux.x64.Release" "./Linux.x86.Debug" "./Linux.x86.Release")

for dir in "${directories[@]}"
do
    rm -rf "$dir"
done
