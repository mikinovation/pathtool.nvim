#!/bin/bash

echo "Running pathtool.nvim tests..."
busted -e "package.path='./lua/?.lua;./lua/?/init.lua;'..package.path" test/*.lua
