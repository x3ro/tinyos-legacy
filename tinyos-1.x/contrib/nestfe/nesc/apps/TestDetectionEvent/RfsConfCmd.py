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

# This script loads the basic pytos environment for a specific application.
#
# The script must be run in the application directory or told where it is,
# and must be told which platform to import (first parameter).  It will then import all
# nesc types, enums, and messages defined in the application.
#
# If the user has a node running this application and indicates how to connect to
# that node (second parameter), the script will also load any rpc functions and ram symbols
# in the application and present them to the user.
#
# In lieu of the first and second parameters, the TINYOS_DEFAULT_PLATFORM and MOTECOM
# environment variables can be used.
#
# usage:
# $     Pytos.py [buildDir] [motecom]
#
# Where "buildDir" is
# 1.  only a platform name, eg "pc" or "telosb"
# 2.  a path to the build dir, eg. "../../TestRpc/build/telosb"
#
# And where motecom is the standard comm port definition, eg "sf@localhost:9001"
#
# Once the application is loaded, the "app" variable will be available, from which you
# can access all imported enums, types, messages, rpc functions or ram symbols.
#
# Be sure to set the tosbase variable below if you are using a TosBase

import sys
import pytos.tools.Rpc as Rpc
import pytos.tools.RamSymbols as RamSymbols
import pytos.util.NescApp as NescApp

buildDir = None
if len(sys.argv) > 1:
    buildDir = sys.argv[1]

port = None
if len(sys.argv) > 2:
    port = sys.argv[2]

# import the enums and types in the nesc app that I am working with
app = NescApp.NescApp(buildDir, port, tosbase=True)

# start the drain tree because we commented out line 164 of RoutingMessages so that
#drain trees are no longer automatically built.  This was done so that multiple users
# of the network could share drain trees.
app.rpc.receiveComm.maintainTree()

#set the locations of the nodes based on the cfg file
from KrakenTools import *
#locationSet('/home/kamin/tinyos-1.x/contrib/nestfe/configurations/RFSConfCtr.cfg')

#set the detection mode to simple threshold
from TestDetectionEvent import *
#detectMode('simple')
