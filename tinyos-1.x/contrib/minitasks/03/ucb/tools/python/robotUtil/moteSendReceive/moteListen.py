#!/usr/bin/python
#call from cmd line: ./moteListen HOST PORT PACKET_TYPE
# PACKET_TYPE be "mag" or "croute" without the quotes
#eg, use localhost 9000 for serial forwarder
#  or use p2c 50001 for gps server

import socket, time, sys
import motePacket
from config import *
from fpformat import fix


# Parameters
packetLength = 36


packetType = sys.argv[3]
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect( ( sys.argv[1] , int(sys.argv[2]) ) )
s.setblocking(0)

buffer = ""
while True :

    try:
        #print "Checking for mote packet..."
        packet = None
        while not packet:
            buffer = buffer + s.recv(1)
            if len( buffer ) >= packetLength:
                buffer = buffer[-packetLength:]
                if packetType == "mag":
                    packet = motePacket.findMagPacket( buffer )
                elif packetType == "croute":
                    packet = motePacket.findCRoutePacket( buffer )
                #print packet
                #print `buffer`
        #print "...Packet Found:"
        #print packet
        print "mote:(" +fix(packet["magObjectX"],2)+ ", " +fix(packet["magObjectY"],2)+ ")"
        #print "mote:(" +fix(packet["magXSumFloat"],2)+ ", " +fix(packet["magYSumFloat"],2)+ \
        #      ")  gps:(" +fix(packet["gpsX"],2)+ ", " +fix(packet["gpsY"],2)+ ")"
        packet = ""
        
    except socket.error :
        pass
        #print "...no packet found"
        #print ""
        #pass  #just stop looking for a valid packet and move on

    #print "sleeping for 0.5 seconds..."
    #print ""
    time.sleep(0.001)
