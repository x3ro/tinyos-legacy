#!/usr/bin/python
# $Id: old_run_app.py,v 1.1 2006/12/01 00:57:00 binetude Exp $

# "Copyright (c) 2000-2003 The Regents of the University  of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement is
# hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
# CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
#
# Copyright (c) 2002-2003 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.
#
# @author Sukun Kim <binetude@cs.berkeley.edu>
#

import os

motes = [58, 27, 41, 26, \
30, 36, 34, 68, 74, \
67, 53, 40, 51, 57, \
55, 64, 62, 63, 70, \
44, 71]
MAX_RETRY = 10



while True:

  os.system('date')
  os.system('sleep 1')
  os.system('java net.tinyos.sentri.DataCenter releaseRoute')
  
  
  
  os.system('sleep 1')
  os.system('java net.tinyos.sentri.DataCenter eraseFlash')
  
  
  
  for i in range(6):
    os.system('sleep 20')
    os.system('java net.tinyos.sentri.DataCenter ledOff')
  
  for i in motes:
    mote = str(i)
    os.system('sleep 1')
    result = 0
    os.system('java net.tinyos.sentri.DataCenter networkInfo ' + mote)
    if result != 0:
      os.system('sleep 10')
  
  os.system('sleep 120')
  os.system('java net.tinyos.sentri.DataCenter fixRoute')
  
  
  
  os.system('sleep 60')
  os.system('java net.tinyos.sentri.DataCenter startSensing 48000 1000 -chnlSelect 31 -samplesToAvg 5')
  
  for i in motes:
    mote = str(i)
    for j in range(MAX_RETRY):
      os.system('sleep 1')
      result = 0
      os.system('java net.tinyos.sentri.DataCenter readData -dest ' + mote)
      if result == 0:
        break
  
  
  
  os.system('sleep 1')
  os.system('java net.tinyos.sentri.DataCenter releaseRoute')
  
