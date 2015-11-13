#!/bin/sh

my_ip=$(hostname -i)

while true; do
  out="{ "
  first=true
  for var in "$@"
  do
    if ! $first; then
      out="$out, "
    fi
    first=false
    list=`nmap -sS -p $var $my_ip/24 | awk -v port=$var -v RS="" '$0 ~ port "/tcp open"' | awk '$0 ~ "Nmap scan report for" { gsub(/[()]/,""); printf "\"%s\",", $6; }'`
    list=`echo $list | sed 's/,$//'`
    out="$out\"$var\":[$list]"
  done
  out="$out }"
  echo $out

  sleep 30
done
