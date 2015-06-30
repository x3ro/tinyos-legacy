#!/bin/bash
#/* $Id: intel-program.sh,v 1.2 2004/03/06 18:55:09 kaminw Exp $ */
#/*////////////////////////////////////////////////////////*/
#/**
# * Author: Terence Tong, Alec Woo
# */
#/*////////////////////////////////////////////////////////*/

declare -a MOTES
declare -a MOTE_IDS

#MOTES=("192.168.1.10" "192.168.1.11" "192.168.1.12" "192.168.1.13" "192.168.1.14" "192.168.1.20" "192.168.1.22" "192.168.1.23" "192.168.1.24" "192.168.1.25" "192.168.1.27" "192.168.1.29" "192.168.1.28")

#Define the MOTE_IDS array, in case we are using the above defined MOTES array
for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))
do
  MOTE_IDS[$MOTEID]=$MOTEID
done



#192.168.1.19
#192.168.1.26

#MOTES=("c62b27a" "c62b264" "c62b277" "c62b255" "c62b260" "c62b26a" "c62b262" "c62b27e" "c62b279" "c62b263" "c62b268" "c62b261" "c62b257" "c627f34")

#"c62b27c" 
#c62b266
#c634776
#c634719
#c62b275
#c62d4eb
#c62b26b
#c62b274

PLATFORM=$RSC_PLATFORM
#If undefined RSC_PLATFORM
if [ -z "$RSC_PLATFORM" ];
then
  echo "RSC_PLATFORM not defined ($RSC_PLATFORM)" 
  PLATFORM="mica2dot"
fi

#If defined RSC_MOTE_IDS
if [ -n "$RSC_MOTE_IDS" ];
then
  eval `echo $RSC_MOTE_IDS   | sed 's/^/MOTE_IDS=\(\"/' | sed 's/$/\"\)/' | sed 's/:/\" \"/g'`
fi

#If defined RSC_MOTE_ADDRS
if [ -n "$RSC_MOTE_ADDRS" ];
then
  eval `echo $RSC_MOTE_ADDRS | sed    's/^/MOTES=\(\"/' | sed 's/$/\"\)/' | sed 's/:/\" \"/g'`
fi


if [ -z "$RSCPATH" ];
then
  echo "You didn't define your RSCPATH. Define the path and try me again"
fi


#for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))
#do
  #echo "Mote ${MOTES[$MOTEID]} id ${MOTE_IDS[$MOTEID]}"
#done

function stab() {

   ## killing unfinished process
   ps ax | grep $1 | awk '{print $2}' | xargs -i kill -9 {} &> /dev/null

}

function download() {

    rm -rf /tmp/rsc.* $> /dev/null
    ## create temp directory
    TEMPDIR=`mktemp -d /tmp/rsc.XXXXXXXXXX`

    echo "Log files in $TEMPDIR"
    ## Handles Control c
    trap 'echo "Control c signaled. See $TEMPDIR for log file. Exiting ...."; stab uisp; exit 0' 2

    NUM_MOTES=${#MOTES[@]}
    ## while the length unfinishing motes is not 0
      echo "Enter Downloading Phase ...."
      MOTEID=0
      for ((MOTEID=0; MOTEID < $NUM_MOTES ; MOTEID++))
      do
          MOTE="${MOTES[$MOTEID]}"
	  if [ "$MOTE" == "" ];
	  then
	    continue
	  fi
	  echo "Attempting downloading Mote $MOTEID with address $MOTE ...."
          TMPMOTEID="${MOTE_IDS[$MOTEID]}"
          echo "Mote Id $TMPMOTEID"
	  $RSCPATH/program.sh --download --networkhost=$MOTE --platform=$PLATFORM --moteid=$TMPMOTEID &> $TEMPDIR/$MOTE & 
      done
      ## make sure to give enough time otherwise keep on restarting      

}

function loadinp() {
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))
    do
        MOTE="${MOTES[$MOTEID]}"      
        echo "Uploading INP for $MOTE"
	$RSCPATH/program.sh --loadinp --networkhost=$MOTE --platform=$PLATFORM
    done
}




function resume() {
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))    
    do
        MOTE="${MOTES[$MOTEID]}"          
    	if (("$MOTEID" >= "$1"))
	then
          echo "Downloading for $MOTE"
	  $RSCPATH/program.sh --download --networkhost=$MOTE --platform=$PLATFORM --moteid=$MOTEID 
	fi
    done
}



function ping() {
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))        
    do
        MOTE="${MOTES[$MOTEID]}"              

	echo "$RSCPATH/program.sh --ping --networkhost=$MOTE"
	$RSCPATH/program.sh --ping --networkhost=$MOTE 
    done
}

function erase() {
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))            
    do
        MOTE="${MOTES[$MOTEID]}"              
	$RSCPATH/program.sh --erase --networkhost=$MOTE  
    done
}

function doreset() {
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))
    do
        MOTE="${MOTES[$MOTEID]}"      
        echo "Reseting $MOTE"
	java Logger --reset --source=network@$MOTE:10002
    done
}


function listen() {
    cd $RSCPATH
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))            
    do
        MOTE="${MOTES[$MOTEID]}"              
        java Logger --display --source=network@$MOTE:10002 &
	sleep 1
    done
}
# url, user, password, tablename
function create_table() {
    cd $RSCPATH
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))            
    do
        MOTE="${MOTES[$MOTEID]}"                  
        java Logger --createtable --url=$1 --user=$2 --pass=$3 --tablename=$4_n$MOTEID &
	sleep 1
    done
}

# url, user, password, tablename
function drop_table() {
    cd $RSCPATH
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))            
    do
        MOTE="${MOTES[$MOTEID]}"                  
        java Logger --droptable --url=$1 --user=$2 --pass=$3 --tablename=$4_n$MOTEID &
	sleep 1
    done
}

# url, user, password, tablename
function clear_table() {
    cd $RSCPATH
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))            
    do
        MOTE="${MOTES[$MOTEID]}"                  
        java Logger --cleartable --url=$1 --user=$2 --pass=$3 --tablename=$4_n$MOTEID &
	sleep 1
    done
}

# url, user, password, tablename
function duration() {
    cd $RSCPATH
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))            
    do
        MOTE="${MOTES[$MOTEID]}"              
        java Logger --duration --url=$1 --user=$2 --pass=$3 --tablename=$4_n$MOTEID
	echo ""
	sleep 1
    done
}

#url, user, password, tablename
function logging() {
    cd $RSCPATH
    for ((MOTEID=0; MOTEID < ${#MOTES[@]} ; MOTEID++))            
    do
        MOTE="${MOTES[$MOTEID]}"              
        java Logger --logging --source=network@$MOTE:10002 --url=$1 --user=$2 --pass=$3 --tablename=$4_n$MOTEID --display &
        sleep 1
    done
}
function help() {
  echo "Usage: intel-program.sh [options]"
  echo "[options] are:"
  echo "  --help                    Display this message."
  echo "  --logging                 Log Packets to Database"
  echo "                            Required Options (url, user)"
  echo "                            And (password, tablename)";
  echo "  --createtable             Create Table"
  echo "                            Required Options (url, user, password, tablename)";
  echo "  --cleartable              Clear Tables"
  echo "                            Required Options (url, user, password, tablename)";
  echo "  --droptable               Drop Tables"
  echo "                            Required Options (url, user, password, tablename)";
  echo "  --duration                Summary of Experiements"
  echo "                            Required Options (url, user, password, tablename)";  
  echo "  --listen                  Display Packet"
  echo "  --ping                    Ping Node"
  echo "  --erase                   Erase Node"
  echo "  --download                Download Node"
  echo "  --loadinp                 Load INP Bootload"
  echo "  --resume                  Resume Download"
  echo "                            Required Options (moteid)";
  echo "  --reset                   Reset EPRB"
  echo "  --url=<ip/dbname>         URL e.g. localhost/rsc"
  echo "  --user=<username>         Database Username"
  echo "  --password=<password>     Database Password"
  echo "  --tablename=<tablename>   Database Tablename"
  echo "  --moteid=<id>             MoteID"
}


for arg in $*
do
  if [ ${arg:0:6} == "--help" ];
  then
    DOHELP="true";
  fi

  if [ ${arg:0:9} == "--logging" ];
  then
    DOLOGGING="true"
  fi

  if [ ${arg:0:13} == "--createtable" ];
  then
    DOCREATETABLE="true";
  fi

  if [ ${arg:0:12} == "--cleartable" ];
  then
    DOCLEARTABLE="true";
  fi

  if [ ${arg:0:11} == "--droptable" ];
  then
    DODROPTABLE="true";
  fi

  if [ ${arg:0:11} == "--duration" ];
  then
    DODURATION="true";
  fi
  
  if [ ${arg:0:8} == "--listen" ];
  then
    DOLISTEN="true";
  fi

  if [ ${arg:0:6} == "--ping" ];
  then
    DOPING="true";
  fi

  if [ ${arg:0:7} == "--erase" ];
  then
    DOERASE="true";
  fi

  if [ ${arg:0:10} == "--download" ];
  then
    DODOWNLOAD="true";
  fi

  if [ ${arg:0:9} == "--loadinp" ];
  then
    DOLOADINP="true";
  fi

  if [ ${arg:0:10} == "--resume" ];
  then
    DORESUME="true";
  fi

  if [ ${arg:0:9} == "--reset" ];
  then
    DORESET="true";
  fi

  
  if [ ${arg:0:12} == "--tablename=" ];
  then
    TABLENAME=${arg#--tablename=};
  fi

  if [ ${arg:0:6} == "--url=" ];
  then
    URL=${arg#--url=};
  fi

  if [ ${arg:0:7} == "--user=" ];
  then
    USER=${arg#--user=};
  fi

  if [ ${arg:0:11} == "--password=" ];
  then
    PASSWORD=${arg#--password=};
  fi

  if [ ${arg:0:9} == "--moteid=" ];
  then
    MOTEID=${arg#--moteid=};
  fi

  
done

if [ "$DOLOGGING" == "true" ];
then
  if [ -z $URL ] || [ -z $USER ] || [ -z $PASSWORD ] || [ -z $TABLENAME ];
  then
    help
  else
    logging $URL $USER $PASSWORD $TABLENAME
  fi

fi

if [ "$DOCREATETABLE" == "true" ];
then

  if [ -z $URL ] || [ -z $USER ] || [ -z $PASSWORD ] || [ -z $TABLENAME ];
  then
    help
  else
    create_table $URL $USER $PASSWORD $TABLENAME
  fi
fi


if [ "$DOCLEARTABLE" == "true" ];
then

  if [ -z $URL ] || [ -z $USER ] || [ -z $PASSWORD ] || [ -z $TABLENAME ];
  then
    help
  else
    clear_table $URL $USER $PASSWORD $TABLENAME
  fi
fi

if [ "$DODROPTABLE" == "true" ];
then

  if [ -z $URL ] || [ -z $USER ] || [ -z $PASSWORD ] || [ -z $TABLENAME ];
  then
    help
  else
    drop_table $URL $USER $PASSWORD $TABLENAME
  fi
fi

if [ "$DODURATION" == "true" ];
then

  if [ -z $URL ] || [ -z $USER ] || [ -z $PASSWORD ] || [ -z $TABLENAME ];
  then
    help
  else
    duration $URL $USER $PASSWORD $TABLENAME
  fi
fi




if [ "$DOLISTEN" == "true" ];
then
  listen
fi

if [ "$DOERASE" == "true" ];
then
  erase

fi

if [ "$DODOWNLOAD" == "true" ];
then
  download
fi


if [ "$DORESET" == "true" ];
then
  doreset
fi

if [ "$DOLOADINP" == "true" ];
then
  loadinp
fi

if [ "$DORESUME" == "true" ];
then
  if [ -z $MOTEID ];
  then
    help
  else
    resume $MOTEID
  fi
fi

if [ "$DOPING" == "true" ];
then
  ping
fi

if [ "$DOHELP" == "true" ];
then
  help
fi

wait
