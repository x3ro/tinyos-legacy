#!/usr/bin/python

#usage: ./sendMagPacket mote_meters_x mote_meters_y

import socket, sys
import motePacket, moteGps

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect( ("localhost", 9000) )

#convert to gps coordinates
(gpsX, gpsY) = moteGps.moteToGps(( float(sys.argv[1]) , float(sys.argv[2]) ))

try:
    p = motePacket.makeMagPacketBytes( gpsX , gpsY , 1 )
    #print `p`
    s.send( p )
except socket.error :
    print "Socket Error"

s.close()
