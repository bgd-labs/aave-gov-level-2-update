#!/bin/bash

MY_DATE=$(date)
sed -i "1s/^/\/\/ $MY_DATE\n/" $1