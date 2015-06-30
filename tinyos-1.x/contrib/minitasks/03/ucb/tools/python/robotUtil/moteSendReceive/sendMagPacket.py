#!/usr/bin/python

import socket, sys
import motePacket, moteGps


s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect( ("localhost", 9000) )
gps = GpsBox( "serial,/dev/ttyS3,115200" )


connectionOK = true:
while connectionOK:
    if gps.iterate( PURSUE_GPS_TIMEOUT ):
        try:
            p = motePacket.makeMagPacketBytes( gps.rfs().getCurrentX() ,  -gps.rfs().getCurrentY() , 1)
            print `p`
            s.send( p )
        except socket.error :
            print "Socket Error"
            connectionOK = False
            s.close()
