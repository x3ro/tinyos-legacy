#!/usr/bin/python

from GpsBoxPython import *
from TerminalFile import *
from fpformat import fix
from time import sleep, strftime
from AriaPy import *


#parameters
gpsTimeOut = 0.4
logFileName = "/home/guest/work/robotUtil/logGps/logFiles/" + strftime( "%Y.%m.%d.%H.%M.%S" ) +".gpsLog"
sleepTime = 0.5


def printColumns():
    print "Columns in log file:"
    print "prtkb.week (1)"
    print "prtkb.time (2)"
    print "prtkb.lag (3)"
    print "prtkb.sats (4)"
    print "prtkb.sats_RTK (5)"
    print "prtkb.sats_RTK_L1_L2 (6)"
    print "prtkb.latitude (7)"
    print "prtkb.longitude (8)"
    print "prtkb.height (9)"
    print "prtkb.undulation (10)"
    print "prtkb.id (11)"
    print "prtkb.dev_latitude (12)"
    print "prtkb.dev_longitude (13)"
    print "prtkb.dev_height (14)"
    print "prtkb.status_solution (15)"
    print "prtkb.status_RTK (16)"
    print "prtkb.pos_type (17)"
    print "prtkb.idle (18)"
    print "prtkb.station (19)"
    print "vlhb.week (20)"
    print "vlhb.seconds (21)"
    print "vlhb.latency (22)"
    print "vlhb.age (23)"
    print "vlhb.hspeed (24)"
    print "vlhb.tog (25)"
    print "vlhb.vspeed (26)"
    print "vlhb.status_solution (27)"
    print "vlhb.status_velocity (28)"
    print "x (29)"
    print "y (30)"
    print "t - seconds since start (31)"


s = TerminalFile( sys.stdin )  #scan stdin for keypress
gps = GpsBox( "serial,/dev/ttyS3,115200" )
log = file( logFileName , "w" )
initTime = ArTime()

print "Beginning GPS test ..."
print "Log file: " + logFileName
print ""
printColumns()
print ""
print "Press q to quit..."
while s.getch() != "q" :

    if gps.iterate( gpsTimeOut ):

        prtkb = gps.prtkb()
        vlhb = gps.vlhb()
        x = gps.rfs().getCurrentX()
        y = gps.rfs().getCurrentY()
        t = initTime.secSince()

        newLogEntryStr = "%i " % ( prtkb.week ) + \
                         "%f " % ( prtkb.time ) + \
                         "%f " % ( prtkb.lag ) + \
                         "%i " % ( prtkb.sats ) + \
                         "%i " % ( prtkb.sats_RTK ) + \
                         "%i " % ( prtkb.sats_RTK_L1_L2 ) + \
                         "%f " % ( prtkb.latitude ) + \
                         "%f " % ( prtkb.longitude ) + \
                         "%f " % ( prtkb.height ) + \
                         "%f " % ( prtkb.undulation ) + \
                         "%i " % ( prtkb.id ) + \
                         "%f " % ( prtkb.dev_latitude ) + \
                         "%f " % ( prtkb.dev_longitude ) + \
                         "%f " % ( prtkb.dev_height ) + \
                         "%i " % ( prtkb.status_solution ) + \
                         "%i " % ( prtkb.status_RTK ) + \
                         "%i " % ( prtkb.pos_type ) + \
                         "%i " % ( prtkb.idle ) + \
                         "%i " % ( prtkb.station )  + \
                         "%i " % ( vlhb.week ) + \
                         "%f " % ( vlhb.seconds ) + \
                         "%f " % ( vlhb.latency ) + \
                         "%f " % ( vlhb.age ) + \
                         "%f " % ( vlhb.hspeed ) + \
                         "%f " % ( vlhb.tog ) + \
                         "%f " % ( vlhb.vspeed ) + \
                         "%i " % ( vlhb.status_solution ) + \
                         "%i " % ( vlhb.status_velocity ) + \
                         "%f " % ( x ) + \
                         "%f " % ( y ) + \
                         "%i" % ( t)

        
        #print newLogEntryStr
        log.write( newLogEntryStr + "\n" )
        log.flush()
        sleep( sleepTime )
        
#print ""
#printColumns()
#print ""
print "...ending GPS test"
log.close()
