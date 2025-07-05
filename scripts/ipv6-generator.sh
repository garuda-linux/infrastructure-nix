#!/usr/bin/env bash
count=1
count_max=10
network="2a01:4f8:2200:30ac"

# -----
# Generate Random Address
# Thx to Vladislav V. Prodan [https://gist.github.com/click0/939739]
# -----
GenerateAddress() {
  array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
  a=${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}
  b=${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}
  c=${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}
  d=${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}
  echo "$network":"$a":"$b":"$c":"$d"
}

while [ "$count" -lt "$count_max" ]; do
  GenerateAddress
  count=$((count + 1))
done
