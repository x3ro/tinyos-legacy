#                                                                      tab:4
#  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
#  downloading, copying, installing or using the software you agree to
#  this license.  If you do not agree to this license, do not download,
#
#
#                                                                      tab:4
# "Copyright (c) 2000-2003 The Regents of the University  of California.
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
#
#                                                                     tab:4
# Copyright (c) 2003 Intel Corporation
# All rights reserved Contributions to the above software program by Intel
# Corporation is program is licensed subject to the BSD License, available at
# http://www.opensource.org/licenses/bsd-license.html
#
#
#
# Authors:      Steve Conner, Mark Yarvis, York Liu
#
#

lappend auto_path .
packet_format_init 1
global pktfmt

settings_gui_common_init $pktfmt(C_SETTINGS)


#set setgrp [settings_gui_common_create_group 1  "Feedback List"]
#settings_gui_common_add_rangeval         $setgrp "FB ID:"             1 255 1
#settings_gui_common_add_vchecklist $setgrp "ID List:"           [list {1 0} {2 0} {3 0} {4 0} {5 0} {6 0} {7 0} {8 0} {9 0} {10 0} {11 0} {12 0} {13 0} {14 0} {15 0} {20 0}]

#set setgrp [settings_gui_common_create_group 2  "Feedback ID"]
#settings_gui_common_add_incrval          $setgrp "FB ID:"             1 255 1

#set setgrp [settings_gui_common_create_group 4  "Setting Version"]
#settings_gui_common_add_setver $setgrp

set setgrp [settings_gui_common_create_group 5  "Pot Set"]
settings_gui_common_add_rangeval         $setgrp "Pot Val:"           1 255 72

set setgrp [settings_gui_common_create_group 7  "Traceroute"]
settings_gui_common_add_rangeval         $setgrp "Xmit Interval:"     1 255 10

set setgrp [settings_gui_common_create_group 8  "DSDV PktFwd"]
settings_gui_common_add_checkbox         $setgrp "Passive Ack"        0

set setgrp [settings_gui_common_create_group 9  "DSDV Rupdate"]
settings_gui_common_add_rangeval         $setgrp "Rupdate Interval:"  1 255 30
settings_gui_common_add_checkbox         $setgrp "Randomize"          1

#set setgrp [settings_gui_common_create_group 10 "NbrHistory"]
#settings_gui_common_add_rangeval         $setgrp "Timeout:"           1 255 20
#settings_gui_common_add_rangeval         $setgrp "Penalty:"           1 255 5

#set setgrp [settings_gui_common_create_group 11 "NbrQuality"]
#settings_gui_common_add_rangeval         $setgrp "Th0:"               1 255 30
#settings_gui_common_add_rangeval         $setgrp "Th1:"               1 255 60
#settings_gui_common_add_rangeval         $setgrp "Th2:"               1 255 85

#set setgrp [settings_gui_common_create_group 14 "DSDV Metric"]
#settings_gui_common_add_rangeval         $setgrp "Est0:"               1 255 28
#settings_gui_common_add_rangeval         $setgrp "Est1:"               1 255 9
#settings_gui_common_add_rangeval         $setgrp "Est2:"               1 255 3
#settings_gui_common_add_rangeval         $setgrp "Est3:"               1 255 1

#set setgrp [settings_gui_common_create_group 12 "Tx Control"]
#settings_gui_common_add_checkbox         $setgrp "Tx Enable"          1

set setgrp [settings_gui_common_create_group 13 "SoI Control"]
settings_gui_common_add_optionlist      $setgrp "Flags"              [list {"SoI On" 0x01} {"Add Adj" 0x02} {"Rmv Adj" 0x04}]  0x01
settings_gui_common_add_rangeval        $setgrp "ValFunc:"           1 255 2
settings_gui_common_add_addrlist        $setgrp "Node List"          "1 2 3"

#set setgrp [settings_gui_common_create_group 15 "Metric Measurement"]
#settings_gui_common_add_checkbox         $setgrp "Enable"        1

#set setgrp [settings_gui_common_create_group 16 "Mesh Interface"]
#settings_gui_common_add_checkbox         $setgrp "Enable"        1
#settings_gui_common_add_addrlist        $setgrp "Node List"          "1 2 3"

#set setgrp [settings_gui_common_create_group 20 "Energy Measure"]
#settings_gui_common_add_checkbox         $setgrp "Measure Start"          1

#set setgrp [settings_gui_common_create_group 21  "Static Route"]
#settings_gui_common_add_rangeval         $setgrp "Destination Node:"           0 255 0
#settings_gui_common_add_rangeval         $setgrp "Next Hop:"           0 255 0
#set setgrp [settings_gui_common_create_group 23  "Reset"]

set setgrp [settings_gui_common_create_group 24 "Vote demo reset vote:" ]
settings_gui_common_add_checkbox         $setgrp "Enable"          1

set setgrp [settings_gui_common_create_group 25 "Vote demo buzzer:" ]
settings_gui_common_add_checkbox         $setgrp "Enable"          1

settings_gui_common_start
