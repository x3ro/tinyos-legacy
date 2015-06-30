#!/bin/bash
I=0

for ((;$I<20;I = $I+1)); do
  grep "$I: CLIQUE" clique-50.txt | grep -v "[0-9]$I: CLIQUE"
  echo 

done

