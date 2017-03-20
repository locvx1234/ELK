#!/bin/bash

to="locvx1234@gmail.com"
from="admin@kibana.ved.vn"
subject="Report everyday"
body="Report in file attach"
declare -a attachments
i=0
while read line
do
    attachments[ $i ]="$line"
    (( i++ ))
done < <(find /var/lib/docker/volumes/709f2958d8d8ad501ace40e474560d5be8b322656e2ad37f4adaa4e50f611943/_data -mmin -60 -name "*.pdf")


declare -a attargs
for att in "${attachments[@]}"; do
  attargs+=( "-A"  "$att" )
done

mail -s "$subject" -r "$from" "${attargs[@]}" "$to" <<< "$body"
