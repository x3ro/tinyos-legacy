#!/bin/bash

# FIRST ARG: PLATFORM
# SECOND ARG: HOST
# THIRD ARG: MOTE ID

EXTRA_PARAM="-dprog=stk500 -dpart=ATmega128"

function download() {
  echo ""
  echo "------------------------------------------------------------"
  echo ">>> Programming moteid $3 address $2 platform $1 ... <<<"
  echo ">>> Setting Fuse Bit ..."
  if [ "$1" == "mica" ];
  then
    uisp $EXTRA_PARAM -dhost=$2 --wr_fuse_e=fd
  fi
  if [ "$1" == "mica2" ] || [ "$1" == "mica2dot" ];
  then
    uisp $EXTRA_PARAM -dhost=$2 --wr_fuse_e=ff --wr_fuse_h=d9
  fi
  sleep 1

  TMPBINARY="./build/$1/main.srec"
  IDBINARY="./build/$1/main.id.$3.srec"
  rm -rf $TMPBINARY
  rm -rf $IDBINARY

  echo ">>> Setting Mote Id To $3 ..."
  set-mote-id $TMPBINARY $IDBINARY $3
  sleep 1
  echo ">>> Erasing ..."
  uisp $EXTRA_PARAM -dhost=$2 --erase &&
  sleep 1
  echo ">>> Loading ...."
  uisp $EXTRA_PARAM -dhost=$2 --upload if=$IDBINARY &&
  sleep 1
  echo ">>> Verifying ...."	
  uisp $EXTRA_PARAM -dhost=$2 --verify if=$IDBINARY &&
  echo ">>> Done ...."
}
function erase() {
  echo ">>> Erasing $1 ..."
  uisp $EXTRA_PARAM -dhost=$1 --erase
}


function ping_node() {
  echo ""
  echo "------------------------------------------------------------"  
  echo ">>> Pinging $1 ..."
  ping -n 1 $1
}

# host, platform
function loadinp() {
  echo "Loading Xnp Bootloader for $2 on $1"
  if [ "$2" == "mica2" ];
  then
    uisp $EXTRA_PARAM -dhost=$1 --upload if=${TOSDIR}/lib/xnp/inpispm2.srec
  fi
  if [ "$2" == "mica2dot" ];
  then
    uisp $EXTRA_PARAM -dhost=$1 --upload if=${TOSDIR}/lib/xnp/inpispm2d.srec
  fi
}

function help() {
  echo "Usage: program.sh [options]"
  echo "[options] are:"
  echo "  --help                    Display this message."
  echo "  --download                Download Image"
  echo "                            Required Options (networkhost, platform, moteid)";
  echo "  --ping                    Ping Node"
  echo "                            Required Options (networkhost)";
  echo "  --erase                   Erase Node"
  echo "                            Required Options (networkhost)";
  echo "  --loadinp                 Load Xnp Bootloader"
  echo "                            Required Options (networkhost, platform)";
  echo "  --networkhost=<ip>        IP of EPRB"
  echo "  --platform=<platform>     Platform e.g: mica2"
  echo "  --moteid=<id>             Set Mote ID";
}
for arg in $*
do
  if [ ${arg:0:11} == "--download" ];
  then
    DODOWNLOAD="true";
  fi

  if [ ${arg:0:6} == "--help" ];
  then
    DOHELP="true";
  fi

  if [ ${arg:0:8} == "--erase" ];
  then
    DOERASE="true";
  fi

  if [ ${arg:0:7} == "--ping" ];
  then
    DOPING="true";
  fi

  if [ ${arg:0:9} == "--loadinp" ];
  then
    DOLOADINP="true";
  fi

  if [ ${arg:0:11} == "--platform=" ];
  then
    PLATFORM=${arg#--platform=};
  fi

  if [ ${arg:0:14} == "--networkhost=" ];
  then
    NETWORKHOST=${arg#--networkhost=};
  fi

  if [ ${arg:0:9} == "--moteid=" ];
  then
    MOTEID=${arg#--moteid=};
  fi


done

if [ "$DOHELP" == "true" ];
then
  help;
fi

if [ "$DODOWNLOAD" == "true" ];
then
  if [ -z $PLATFORM ] || [ -z $NETWORKHOST ] || [ -z $MOTEID ];
  then
    help;
  else 
    download $PLATFORM $NETWORKHOST $MOTEID
  fi
fi

if [ "$DOPING" == "true" ];
then
  if [ -z $NETWORKHOST ];
  then
    help;
  else
    ping_node $NETWORKHOST
  fi
fi


if [ "$DOERASE" == "true" ];
then
  if [ -z $NETWORKHOST ];
  then
    help;
  else
    erase $NETWORKHOST
  fi
fi

if [ "$DOLOADINP" == "true" ];
then
  if [ -z $NETWORKHOST ] || [ -z $PLATFORM ];
  then
    help;
  else
    loadinp $NETWORKHOST $PLATFORM
  fi
fi


