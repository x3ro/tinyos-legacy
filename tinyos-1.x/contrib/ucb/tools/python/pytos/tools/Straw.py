# "Copyright (c) 2000-2003 The Regents of the University of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement
# is hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
# OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
#
# @author Kamin Whitehouse 
#

import sys, math, Queue
import pytos.tools.Drain as Drain
import pytos.Comm as Comm
from struct import *

class Straw( object ) :

    def __init__( self , app ) :
        self.app=app
        self.linkLatency = .1
        if "StrawM" not in app._moduleNames:
            raise Exception("The StrawM module is not compiled into the application.")

    def read(self, nodeID, strawID, start, size):
        data=[] #store the data in here
        response=None
        while response==None:
            print "pinging node %d" % nodeID
            response = self.app.StrawM.msgDataSize.peek(address=nodeID, timeout=3) #find num bytes/msg
        dataSize = response[0].value['value'].value
        numHops = self.app.enums.DRAIN_MAX_TTL - response[0].getParentMsg(self.app.enums.AM_DRAINMSG).ttl
        self.app.StrawM.sendPeriod.poke(self.linkLatency * numHops * 1000, address=nodeID, responseDesired=False)
        msgs = [0 for i in range(int(math.ceil(size/float(dataSize))))] #keep track of straw msgs in here
        msgQueue = Comm.MessageQueue(10)
        Drain.getDrainObject(self.app)[0].register(self.app.msgs.StrawMsg, msgQueue)
        print "Sucking %d bytes from node %d through Straw %d:" % (size, nodeID, strawID)
        while msgs.count(1) < len(msgs):
            subStart = msgs.index(0) * dataSize
            try:
                subSize = min(size, (msgs.index(1, subStart)*dataSize - subStart) )
            except:  
                subSize = size - subStart
            response = []
            #while response == []:
            self.app.StrawM.read(strawID, subStart, subSize, address=nodeID)
            sys.stdout.write("%d-%d: " % (subStart, subStart+subSize))
            numPrintedChars=0
            while True :
                try:
                    (addr, msg) = msgQueue.get(block=True, timeout=self.linkLatency * numHops * 4)
                    if msg.parentMsg.source == nodeID :#and msgs[msg.startIndex//dataSize] == 0:
                        msgs[msg.startIndex//dataSize] = 1
                        data[msg.startIndex:msg.startIndex+dataSize-1] = msg.data[:]
                        strg = ""
                        for i in range(numPrintedChars) :
                            strg += "\b"
                        strg += "%s/%s" % (msgs.count(1),len(msgs))
                        sys.stdout.write(strg)
                        sys.stdout.flush()
                        numPrintedChars = len(strg)-numPrintedChars
                except Queue.Empty:
                    print ""
                    break
        #now, pack the data so that it can be easily unpacked
        for i in range(len(data)):
            data[i] = pack('B',data[i])
        return ''.join(data[0:size])


