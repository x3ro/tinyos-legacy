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

#This is a simple 9-line script that should plot the average voltage of all responding nodes every 5 minutes

import sys, time, pickle
from pytos.util.NescApp import NescApp
from scipy import gplt

allResponses=[]; iteration=0; numSomething=0;

app = NescApp("build/telosb/", "sf@localhost:9001")
voltages = []
while True:
    total=0
    responses = app.ChargerM.voltageBat.peek(timeout=10)
    for response in responses:
        total += response.value["value"].value
    if len(responses) > 0:
        voltages.append(total/len(responses))
        gplt.plot(voltages, 'notitle with impulses')

        numSomething += 1
        allResponses.append(responses)
        jar = open("voltages.save",'w')
        pickle.dump(voltages, jar)
        jar.close()
    iteration += 1
    print "got %d responses (%d/%d)" % (len(responses),numSomething, iteration)
