#!/bin/bash

MY_DATE=$(date)
sed -i "1s/^/\/\/ downloaded from etherscan at: $MY_DATE\n/" $1