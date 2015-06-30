#!/usr/bin/python
#Call from cmd line: ./gpsServer PORT


import socket, sys, fpformat, time
from GpsBoxPython import *
import motePacket
from config import *


#parameters
gpsTimeOut = 0.2
HOST = ''  # Symbolic name meaning the local host
pauseTime = 1


#serverPort from cmd line
serverPort = int( sys.argv[1] )

#init the gps box
gps = GpsBox( "serial,/dev/ttyS3,115200" )

while True:

    #create a new server socket
    s = None
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    except socket.error, msg:
        s = None

    #bind the socket and make it ready
    try:
        s.bind( (HOST, serverPort) )
        s.listen(1)
    except socket.error, msg:
        s.close()
        s = None

    #did we get a valid server socket open?
    if s is None:
        print "could not open socket"
        sys.exit(1)
    else:
        print "Server started; Listening on port " + fpformat.fix( serverPort , 0 )

    #keep listening for client connections
    while True:

        #wait for an incoming connection
        conn, addr = s.accept()
        print 'Connected by', addr

        #send my gps coordinates over the server socket
        connectionOK = True
        while connectionOK:

            #try to get a new gps update
            if gps.iterate( gpsTimeOut ):

                #get the new coordinates
                x = gps.rfs().getCurrentX()
                y = -gps.rfs().getCurrentY()

                #form the new packet
                bytesToSend = motePacket.makeMagPacketBytes( x , y , address = UART_ADDR )

                #try to send the new packet
                try:
                    conn.send( bytesToSend )
                except socket.error :
                    print "Connection to remote client lost"
                    conn.close()
                    connectionOK = False

                time.sleep( pauseTime )
