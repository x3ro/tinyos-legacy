# This is an installation script for the bash shell.  It semi-automates
# the installation of Agilla onto a bunch of motes.
#
# Author: Chien-Liang Fok
# Last Modified: 4-24-2005

echo Recompile? [Y/n]
read response
if 
  test ${response:-y} = y -o ${response:-y} = Y 
then
  make mica2
fi
count=0
go=1
while 
  test ${go} -eq 1
do
  echo
  echo --------------------------------------------------------------------------
  echo Please insert a mote onto the programmer.  What is the address [${count}]? \(q to quit\)
  read address
  if 
    test ${address:-$count} = q
  then
    go=0
  fi
  if 
    test $go -eq 1
  then
    $count = ${address:-$count}
    make reinstall.$count micaz mib510,/dev/ttyUSB0
    count=`expr ${count} + 1`
  fi
done
