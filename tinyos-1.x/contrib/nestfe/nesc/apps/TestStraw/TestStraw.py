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
# $     TestRpc.py telosb
# $     TestRpc.py telosb sf@localhost:9001
#
# then, you can call "data=straw.read(int dest, long start, long size, byte[] bffr)"

import sys
from jpype import *
#import pytos.tools.straw as straw
import pytos.util.NescApp as NescApp
import pytos.Comm as Comm


buildDir = None
if len(sys.argv) > 1:
    buildDir = sys.argv[1]

port = None
if len(sys.argv) > 2:
    port = sys.argv[2]

# import the enums and types in the nesc app that I am working with
app = NescApp.NescApp(buildDir, port, tosbase=True)

comm = Comm.Comm()
comm.connect('sf@localhost:9001')
mif = comm._moteifCache._moteif["sf@localhost:9001"]
drainConnector= app.rpc.receiveComm._javaParents[1]
straw = jimport.straw.Straw(mif, drainConnector)

address=2
start = 0
size=20000
bytes = JArray(JByte,1)(size)
straw.read(address, start, size, bytes)

