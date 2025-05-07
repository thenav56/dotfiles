#!/bin/bash

git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  grep '^blob' | \
  tee /tmp/git-blobs.txt | \
  sort -k3 -n -r | \
  head -n 20 | \
  awk '{
    size=$3;
    split("B KB MB GB TB", unit);
    for (i=1; size>=1024 && i<5; i++) size/=1024;
    printf "%s\t%.2f %s\t%s\n", $2, size, unit[i], substr($0, index($0,$4))
  }'

echo ""
echo "Total repository blob size:"

awk '{s+=$3} END {
  split("B KB MB GB TB", unit);
  for (i=1; s>=1024 && i<5; i++) s/=1024;
  printf "  %.2f %s\n", s, unit[i]
}' /tmp/git-blobs.txt

