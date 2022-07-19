#!/bin/bash

git diff --no-index --ignore-space-at-eol $1 $2 > diffs/$3-diff.md 
sed -i '1s/^/```/' diffs/$3-diff.md