#!/bin/sh
#$Id: MakeTelos.sh,v 1.2 2004/01/08 22:50:01 cssharp Exp $

###
### Define these environment variables in your startup script, particular 
### to your installation: TELOSPATH, CWPATH, PEMICROPATH
###

export TELOSPATH="${TELOSPATH:-c:/home/telos}"
export CWPATH="${CWPATH:-c:/apps/CodeWarrior}"
export PEMICROPATH="${PEMICROPATH:-c:/apps/pemicroHCS08}"
export HC08_PATH="${HC08_PATH:-$TOSDIR/../apps/make/hc08}"


###
### Don't need to modify below here to get started
###

[ -z "$1" ] && echo "usage: MakeTelos.sh [AppC.nc]" && exit 0

export TELOSPATH="${TELOSPATH%/}"
export CWPATH="${CWPATH%/}"
export PEMICROPATH="${PEMICROPATH%/}"
export HC08_PATH="${HC08_PATH%/}"

NESC_FILE=$1

PROGNAME=${0##*/}
PROGPATH=${0%$PROGNAME}

CWINCLUDE="$CWPATH/lib/HC08c/include"
TELOSINCLUDE="$TELOSPATH/hc08/include"

docmd () {
  echo ">>>" "$@"
  "$@" || exit $?
}

### Make sure the build directory exists
mkdir -p build/telos

### Create app.c with nesc

docmd ncc -D__HIWARE__ -D__MWERKS__ -I"$CWINCLUDE" $CFLAGS $PFLAGS -S -Os -target=telos -Wall \
   -Wshadow -Wnesc-all -finline-limit=100000 -fnesc-cfile=build/telos/app.c \
  $NESC_FILE -I$TELOSINCLUDE -DDEF_TOS_AM_GROUP=$DEFAULT_LOCAL_GROUP

### Remove an assembly file that nesc insists on creating
rm -f ${NESC_FILE%.nc}.s

### Mangle app.c so that it compiles with the CW HC08 compiler
docmd perl -w -i.orig $PROGPATH/TelosMangleAppC.pl build/telos/app.c

### Build the binary application app.exe
cd build/telos 
docmd make -f $HC08_PATH/MakeHC08 app.exe
cd ../..

