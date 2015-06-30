#!/usr/bin/python
# $Id: test_app.py,v 1.1 2006/12/01 00:57:00 binetude Exp $

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

motes = [81, 80, 52, 49, 42, \
46, 21,  7, 43, 60, \
47, 59, 45, 54, 37, \
48, 76,  6, 38, 75, \

14, 50, 86, 92, \
82, 78, 77, \
69,  5, 12, 79, \

73,  9, 65, 71, 44, \
70, 63, 62, 64, 89, \
57, 51, 40, 53, 67, \
74, 68, 34, 36, 30, \

25, 24, 28, 23, \
26, 41, 27, 58]



MAX_RETRY = 6



while True:

  os.system('date')
  os.system('sleep 1')
#  os.system('java net.tinyos.sentri.DataCenter releaseRoute')
  
  
  
  os.system('sleep 1')
  os.system('java net.tinyos.sentri.DataCenter eraseFlash')
  
  
  
  for i in range(6):
    os.system('sleep 20')
    os.system('java net.tinyos.sentri.DataCenter ledOff')
  
  os.system('sleep 600')
  for i in motes:
    mote = str(i)
    os.system('sleep 3')
    result = 0
    result = os.system('java net.tinyos.sentri.DataCenter networkInfo ' + mote)
    if result != 0:
      os.system('sleep 10')
  
  os.system('sleep 600')
#  os.system('java net.tinyos.sentri.DataCenter fixRoute')
  
  
  
  os.system('sleep 60')
  os.system('java net.tinyos.sentri.DataCenter startSensing 60000 1000 -chnlSelect 3 -samplesToAvg 10')
  
  os.system('sleep 600')
  for i in motes:
    mote = str(i)
    for j in range(MAX_RETRY):
      os.system('date')
      os.system('sleep 1')
      result = 0
      result = os.system('java net.tinyos.sentri.DataCenter readData -dest ' + mote)
      if result == 0:
        break
	
      os.system('sleep 60')
      if j == MAX_RETRY / 2 - 1:
        os.system('java net.tinyos.sentri.DataCenter releaseRoute')
        os.system('sleep 600')
        os.system('java net.tinyos.sentri.DataCenter fixRoute')
  
  
  
  os.system('sleep 1')
#  os.system('java net.tinyos.sentri.DataCenter releaseRoute')
  
