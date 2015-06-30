import os, string, sys

PORT = 3333
SERVER_MSG_QUEUE_LENGTH = 15
ROBOT_MSG_QUEUE_LENGTH = 10
GPS_SERIAL_PARAMS = "serial,/dev/ttyS0,115200"
GPS_DEFAULT_TIMEOUT = 0.2
#CLIENT_DEFAULT_TIMEOUT = 4
CLIENT_DEFAULT_TIMEOUT = 0.2
LOG_FILE_BYTES = 10*1024*1024

if "HOSTNAME" in os.environ :
    HOSTNAME = os.environ[ "HOSTNAME" ]
else :
    f = file( "/etc/hostname" )
    c = f.readlines()[0]
    f.close()
    import re
    HOSTNAME = re.sub( r"^\s+" , "" , re.sub( r"\s+$" , "" , c ) )

if string.find( HOSTNAME , "monstro" ) >= 0 :
    IS_MONSTRO = True
else :
    IS_MONSTRO = False

PLATFORM = sys.platform
if PLATFORM.find("linux") == 0 :
    PLATFORM = "linux"

