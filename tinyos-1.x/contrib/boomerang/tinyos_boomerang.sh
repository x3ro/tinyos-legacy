# $Id: tinyos_boomerang.sh,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

# tinyos_boomerang.sh: Prepare environment for Boomerang
# Place this file in /etc/profile.d/

export MOTEIV_DIR=/opt/moteiv
export TOSMAKE_PATH=$MOTEIV_DIR/tools/make

# help build files in $TOSDIR/../tools/java/net/tinyos
export MIGFLAGS="-target=telosb -I$TOSDIR/lib/CC2420Radio"
export SURGE_PLATFORM=telos

for a in $MOTEIV_DIR/tools/java/jars/* $MOTEIV_DIR/tools/java
do
  if [ -f /bin/cygwin1.dll ]; then
    export CLASSPATH="`cygpath -w "$a"`;$CLASSPATH"
  else
    export CLASSPATH="$a:$CLASSPATH"
  fi
done

