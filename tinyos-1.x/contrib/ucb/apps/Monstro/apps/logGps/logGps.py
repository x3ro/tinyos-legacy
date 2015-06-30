#!/usr/bin/python

# $Id: logGps.py,v 1.2 2005/04/25 22:38:25 shawns Exp $

#                                                                      tab:2
#  "Copyright (c) 2000-2003 The Regents of the University  of California.  
#  All rights reserved.
#
#  Permission to use, copy, modify, and distribute this software and its
#  documentation for any purpose, without fee, and without written agreement is
#  hereby granted, provided that the above copyright notice, the following
#  two paragraphs and the author appear in all copies of this software.
#  
#  IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
#  DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
#  OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
#  CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#  
#  THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
#  AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
#  ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
#  PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
# 
#  Copyright (c) 2002-2003 Intel Corporation
#  All rights reserved.
# 
#  This file is distributed under the terms in the attached INTEL-LICENSE     
#  file. If you do not find these files, copies can be found by writing to
#  Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
#  94704.  Attention:  Intel License Inquiry.
#

# 
#  @author Shawn Schaffert
#


from GpsBoxPython import *
from fpformat import fix
from time import sleep, strftime
import sys, keyPress


#parameters
gpsTimeOut = 0.4
sleepTime = 0.5


# logfile
if len( sys.argv ) > 1 :
    logFileName = sys.argv[1] + "." + strftime( "%Y.%m.%d.%H.%M.%S" ) + ".gpsLog"
else:
    logFileName = strftime( "%Y.%m.%d.%H.%M.%S" ) + ".gpsLog"


def printColumns():
    print "Columns in log file:"
    print "01 : prtkb.week"
    print "02 : prtkb.time"
    print "03 : prtkb.lag"
    print "04 : prtkb.sats"
    print "05 : prtkb.sats_RTK"
    print "06 : prtkb.sats_RTK_L1_L2"
    print "07 : prtkb.latitude"
    print "08 : prtkb.longitude"
    print "09 : prtkb.height"
    print "10 : prtkb.undulation"
    print "11 : prtkb.id"
    print "12 : prtkb.dev_latitude"
    print "13 : prtkb.dev_longitude"
    print "14 : prtkb.dev_height"
    print "15 : prtkb.status_solution"
    print "16 : prtkb.status_RTK"
    print "17 : prtkb.pos_type"
    print "18 : prtkb.idle"
    print "19 : prtkb.station"
    print "20 : vlhb.week"
    print "21 : vlhb.seconds"
    print "22 : vlhb.latency"
    print "23 : vlhb.age"
    print "24 : vlhb.hspeed"
    print "25 : vlhb.tog"
    print "26 : vlhb.vspeed"
    print "27 : vlhb.status_solution"
    print "28 : vlhb.status_velocity"
    print "29 : x"
    print "30 : y"


kp = keyPress.keyPress()
gps = GpsBox( "serial,/dev/ttyS0,115200" )
log = file( logFileName , "w" )

print "\nLog file: " + logFileName + "\n"
printColumns()
print "\nBeginning GPS test (press q to quit) ..."
while kp.getChar() != "q" :

    if gps.iterate( gpsTimeOut ):

        prtkb = gps.prtkb()
        vlhb = gps.vlhb()
        x = gps.rfs().getCurrentX()
        y = gps.rfs().getCurrentY()

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
                         "%f " % ( y )
        
        
        #print newLogEntryStr
        log.write( newLogEntryStr + "\n" )
        log.flush()
        sleep( sleepTime )
        
print "...ending GPS test"
kp.destroy()
log.close()
