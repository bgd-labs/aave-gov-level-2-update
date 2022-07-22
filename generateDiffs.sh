#!/bin/bash

MY_DATE=$(date)
git diff --no-index --ignore-space-at-eol $1 $2 > diffs/$3-diff.md 
sed -i "1s/^/diff generated with contract downloaded from etherscan at: $MY_DATE\n\n\`\`\`/" diffs/$3-diff.md