#!/bin/bash

MY_DATE=$(date)
sed -i "1s/^/\/\/ downloaded at: $MY_DATE\n/" $1