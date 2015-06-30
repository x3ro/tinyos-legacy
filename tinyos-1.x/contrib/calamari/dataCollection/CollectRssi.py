#!/usr/bin/python -i

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

# to use this test app, get a node running straw and do one of
# $     CollectRssi.py telosb
# $     CollectRssi.py telosb sf@localhost:9001
#
# then, you can call "data=straw.read(int dest, long start, long size, byte[] bffr)"

import sys, time
from jpype import *
import pytos.util.ParseArgs as ParseArgs
import pytos.util.NescApp as NescApp
import pytos.util.nescDecls as nescDecls
import pytos.tools.Straw as Straw
import pytos.Comm as Comm
from Numeric import *

args = ParseArgs.ParseArgs(sys.argv)
app = NescApp.NescApp(args.buildDir, args.motecom, tosbase=True, localCommOnly=True)
straw = Straw.Straw(app)

#nodeIDs = [0, 2]#3, 4, 5, 6, 7, 8, 9, 10]
nodeIDs = [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]
#nodeIDs = [0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 , 12, 13 , 14 , 15 , 16 , 17 , 18 , 19 , 20 , 21 , 22 , 23 , 24 , 25 , 26 , 27 ]

powers = [3, 7, 11, 19, 31]
numberOfChirps = 4
chirpPeriod = 250
strawID = 12
RTT=.5
data = range(max(nodeIDs)+1)
completeData=array([])

for power in powers:
    print "power is %d" % power
    app.RssiCollectionM.dataPos.poke(0, timeout=RTT)
    for node in nodeIDs :
        response = []
        while response == [] :
            response = app.RssiCollectionM.chirp(power, numberOfChirps, chirpPeriod, address=node, timeout=RTT)
        print "node %d chirping" % node
        time.sleep(int(round(chirpPeriod * numberOfChirps /1000)))

    for node in nodeIDs :
        size = []
        while len(size)==0:
            size = app.RssiCollectionM.dataPos.peek(address=node, timeout=RTT)
        data[node] =straw.read(node, strawID, 0, size[0].value["value"].value * 2)

    print "parsing data"

    dataFormat = nescDecls.nescStruct("dataFormat", ("addr", app.types.uint16_t),
                                      ("id", app.types.uint16_t),
                                      ("rssi", app.types.uint16_t),
                                      ("lqi", app.types.uint16_t))

    for d in data:
        if type(d) == str :
            if len(d)%dataFormat.size != 0 :
                raise Exception("data size incorrect! len(d) = %d, dataFormat.size = %d" % (len(d), dataFormat.size))
            for i in range(len(d)/dataFormat.size) :
                dataFormat.setBytes(d[i*dataFormat.size:i*dataFormat.size + dataFormat.size])
                completeData = resize(completeData, [shape(completeData)[0]+1, 6])
                completeData[-1] = array([data.index(d),
                                     dataFormat.addr,
                                     dataFormat.id,
                                     power, 
                                     dataFormat.rssi,
                                     dataFormat.lqi])

import pickle
datafile = file("datafile",'w')
pickle.dump(completeData,datafile)
datafile.close()
