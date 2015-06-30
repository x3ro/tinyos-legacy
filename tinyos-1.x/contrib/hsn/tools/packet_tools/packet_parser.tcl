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

proc packet_format_init {{use_nesc 0}} {
    global pktfmt
    puts "packet_format_init $use_nesc"
    
    set pktfmt(init) 1

    if {$use_nesc > 0} {
	packet_format_init_nesc
    } else {
	packet_format_init_oldtos
    }
}

proc packet_format_init_nesc {} {
    global pktfmt

    set pktfmt(nesc) 1

    set pktfmt(amvalid) [list 2 3 4 5 6 7 8 101 103 104 105 106 240]

    set start 0

    set pktfmt(P_DEST)    [expr $start + 0]
    set pktfmt(P_TYPE)    [expr $start + 2]
    set pktfmt(P_GROUP)   [expr $start + 3]
    set pktfmt(P_LEN)     [expr $start + 4]

    set shop_start 5
    #Single hop message frame
    set pktfmt(P_SNDR)    [expr $shop_start + 0]
    set pktfmt(P_SEQ)     [expr $shop_start + 1]

    set shopdata_start 7
    # DSDV Rupdate
    set pktfmt(P_DRU_DEST)   [expr $shopdata_start + 0]
    set pktfmt(P_DRU_SEQ)    [expr $shopdata_start + 1]
    set pktfmt(P_DRU_COST)   [expr $shopdata_start + 2]
    set pktfmt(P_DRU_PAYLD)  [expr $shopdata_start + 4]
    set pktfmt(P_DRU_SENDER) [expr $shop_start + 0]
    
    # SOI Rupdate
    set pktfmt(P_SOIRU_DEST)   [expr $shopdata_start + 0]
    set pktfmt(P_SOIRU_SEQ)    [expr $shopdata_start + 1]
    set pktfmt(P_SOIRU_ID1)    [expr $shopdata_start + 2]
    set pktfmt(P_SOIRU_FC1)    [expr $shopdata_start + 3]
    set pktfmt(P_SOIRU_VC1)    [expr $shopdata_start + 5]
    set pktfmt(P_SOIRU_ID2)    [expr $shopdata_start + 7]
    set pktfmt(P_SOIRU_FC2)    [expr $shopdata_start + 8]
    set pktfmt(P_SOIRU_VC2)    [expr $shopdata_start + 10]
    set pktfmt(P_SOIRU_PAYLD)  [expr $shopdata_start + 12]
    
    set pktfmt(P_SOI_SPHEREID) 7

    set mhop_start 8
    #Multi hop message frame
    set pktfmt(P_SOI_MHOPSNDR) [expr $mhop_start + 0]
    set pktfmt(P_SOI_MHOPDEST) [expr $mhop_start + 1]
    set pktfmt(P_SOI_MHOPAPP)  [expr $mhop_start + 2]
    set pktfmt(P_SOI_MHOPLEN)  [expr $mhop_start + 3]

    set soi_start 12
    set pktfmt(P_SOI_DSDVNEXT) [expr $start + 0]
    set pktfmt(P_SOI_DSDVSEQ)  [expr $soi_start + 0]
    set pktfmt(P_SOI_DSDVTTL)  [expr $soi_start + 1]
    set pktfmt(P_SOI_DSDVDATA) [expr $soi_start + 2]

    set mhop_start 7
    set pktfmt(P_MHOPSNDR) [expr $mhop_start + 0]
    set pktfmt(P_MHOPDEST) [expr $mhop_start + 1]
    set pktfmt(P_MHOPAPP)  [expr $mhop_start + 2]
    set pktfmt(P_MHOPLEN)  [expr $mhop_start + 3]

    set dsdv_start 11
    set pktfmt(P_DSDVNEXT) [expr $start + 0]
    set pktfmt(P_DSDVSEQ)  [expr $dsdv_start + 0]
    set pktfmt(P_DSDVTTL)  [expr $dsdv_start + 1]
    set pktfmt(P_DSDVDATA)  [expr $dsdv_start + 2]

    set flood_start 11
    set pktfmt(P_FLOODSEQ) [expr $flood_start + 0]
    set pktfmt(P_FLOODTTL) [expr $flood_start + 1]
    set pktfmt(P_FLOODDATA) [expr $flood_start + 2]
    
    set pktfmt(P_PGYBACK_NORMAL)   29
    set pktfmt(PGYBACK_LEN_NORMAL) 5

    set pktfmt(P_PGYBACK_LEN_SOITR) 1

    set pktfmt(TR_OFFSET_LEN)    0
    set pktfmt(TR_OFFSET_LIST)   1

    #Note: these are default values.  If using nesc, these will be overwritten 
    #  based on the actual received packet size.
    set pktfmt(TR_OFFSET_SOI_ADJBITS) 17
    set pktfmt(TR_OFFSET_SOI_SETFB)   19


    set pktfmt(T_FLOOD) 		2

    set pktfmt(T_DSDV)	 	        3
    set pktfmt(T_DSDV_SOI)	        4

    set pktfmt(T_DSDV_RUPDATE_HOPS)  	5
    set pktfmt(T_DSDV_RUPDATE_QUALITY) 	6
    set pktfmt(T_DSDV_RUPDATE_SOI)  	7
    set pktfmt(T_DSDV_RUPDATE_REQ)  	8

    #Note: TinyDB Related, they are hex (101, 103 ... 240)
    set pktfmt(T_TINYDB_QUERY)  	65
    set pktfmt(T_TINYDB_COMMAND)  	67
    set pktfmt(T_TINYDB_QUERY_REQ)  	68
    set pktfmt(T_TINYDB_EVENT)  	69
    set pktfmt(T_TINYDB_STATUS)  	6A
    set pktfmt(T_TINYDB_DATA)	  	F0

    set pktfmt(C_SETTINGS)              2
    set pktfmt(C_TRACEROUTE)            3
    set pktfmt(C_TRACEROUTE_SOI)        4
}

proc packet_format_init_oldtos {} {
    global pktfmt

    set pktfmt(amvalid) [list 102 120 121 122]

    #set start 3
    set start 4

    set pktfmt(PACKET_DATA_LENGTH) 31

    set pktfmt(P_SNDR)    [expr $start + 0]
    set pktfmt(P_SEQ)     [expr $start + 1]
    set pktfmt(P_TYPE)    [expr $start + 2]

    set pktfmt(P_METRIC)  [expr $start + 3]
    set pktfmt(P_RELAY)   [expr $start + 4]
    set pktfmt(P_RNBRCNT) [expr $start + 5]
    set pktfmt(P_ANBRCNT) [expr $start + 6]
    set pktfmt(P_NBRCNT)  [expr $start + 7]
    set pktfmt(P_NBRLST)  [expr $start + 8]

    #RelayOrg2 packets
    set pktfmt(P_RO_SEQ)     [expr $start + 3]
    set pktfmt(P_RO_METRIC)  [expr $start + 4]
    set pktfmt(P_RO_STATE)   [expr $start + 5]
    set pktfmt(P_RO_MYPR)    [expr $start + 6]
    set pktfmt(P_RO_PRNCNT)  [expr $start + 7]
    set pktfmt(P_RO_PRNLST)  [expr $start + 8]

    set pktfmt(P_DRU_DEST)   [expr $start + 3]
    set pktfmt(P_DRU_SEQ)    [expr $start + 4]
    set pktfmt(P_DRU_COST)    [expr $start + 5]
    set pktfmt(P_DRU_SENDER) [expr $start + 6]
    set pktfmt(P_DRU_PAYLD)  [expr $start + 7]
    set pktfmt(P_DRU_PAYLD_TOTALSIZE) [expr $pktfmt(PACKET_DATA_LENGTH) - 7]

    set pktfmt(P_NBRSTATS_PAYLD) [expr $start + 3]
    set pktfmt(P_NBRSTATS_PAYLD_TOTALSIZE) [expr $pktfmt(PACKET_DATA_LENGTH) - 3]


    set pktfmt(P_ORIGSNDR) [expr $start + 3]
    set pktfmt(P_ORIGSEQ)  [expr $start + 4]
    set pktfmt(P_DEST)     [expr $start + 5]
    set pktfmt(P_NEXTHOP)  [expr $start + 6]
    set pktfmt(P_TTL)      [expr $start + 7]
    set pktfmt(P_PAYLD)    [expr $start + 8]

    set pktfmt(P_VOTE_START1)  [expr $start + ($pktfmt(PACKET_DATA_LENGTH) - 8)]
    set pktfmt(P_VOTE_START2)  [expr $start + ($pktfmt(PACKET_DATA_LENGTH) - 7)]
    set pktfmt(P_VOTE_START3)  [expr $start + ($pktfmt(PACKET_DATA_LENGTH) - 6)]
    set pktfmt(P_VOTE_START4)  [expr $start + ($pktfmt(PACKET_DATA_LENGTH) - 5)]
    set pktfmt(P_PGYBACK)      [expr $start + ($pktfmt(PACKET_DATA_LENGTH) - 6)]

    set pktfmt(P_SETTINGS_START)     [expr $start + $pktfmt(PACKET_DATA_LENGTH) - 14]

    set pktfmt(P_SETTINGS_SETVER)    [expr $pktfmt(P_SETTINGS_START) + 0]
    set pktfmt(P_SETTINGS_TXRES)     [expr $pktfmt(P_SETTINGS_START) + 1]
    set pktfmt(P_SETTINGS_HRATE)     [expr $pktfmt(P_SETTINGS_START) + 2]
    set pktfmt(P_SETTINGS_TXRATE)    [expr $pktfmt(P_SETTINGS_START) + 3]
    set pktfmt(P_SETTINGS_ENABLE_MODE)      [expr $pktfmt(P_SETTINGS_START) + 4]
    set pktfmt(P_SETTINGS_DATA_MODE) [expr $pktfmt(P_SETTINGS_START) + 5]
    set pktfmt(P_SETTINGS_MOTION_SENS_RESVAL) [expr $pktfmt(P_SETTINGS_START) + 6]


    set pktfmt(P_SETTINGS_ISMC_SETVER)  [expr $pktfmt(P_SETTINGS_START) + 0]
    set pktfmt(P_SETTINGS_ISMC_TXRES)    [expr $pktfmt(P_SETTINGS_START) + 1]
    set pktfmt(P_SETTINGS_ISMC_TXRATE)   [expr $pktfmt(P_SETTINGS_START) + 2]
    set pktfmt(P_SETTINGS_ISMC_QTHOLD0)  [expr $pktfmt(P_SETTINGS_START) + 3]
    set pktfmt(P_SETTINGS_ISMC_QTHOLD1)  [expr $pktfmt(P_SETTINGS_START) + 4]
    set pktfmt(P_SETTINGS_ISMC_QTHOLD2)  [expr $pktfmt(P_SETTINGS_START) + 5]
    set pktfmt(P_SETTINGS_ISMC_QTIMEOUT) [expr $pktfmt(P_SETTINGS_START) + 6]
    set pktfmt(P_SETTINGS_ISMC_QPENALTY) [expr $pktfmt(P_SETTINGS_START) + 7]
    set pktfmt(P_SETTINGS_ISMC_RUPINT)   [expr $pktfmt(P_SETTINGS_START) + 8]


    # Old packet header fields, for use with code compiled from ismc demo branch
    set pktfmt(P_SETTINGS_OLDISMC_START)    [expr $start + $pktfmt(PACKET_DATA_LENGTH) - 9]
    set pktfmt(P_SETTINGS_OLDISMC_SETVER)   [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 0]
    set pktfmt(P_SETTINGS_OLDISMC_TXRES)    [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 1]
    set pktfmt(P_SETTINGS_OLDISMC_TXRATE)   [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 2]
    set pktfmt(P_SETTINGS_OLDISMC_QTHOLD0)  [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 3]
    set pktfmt(P_SETTINGS_OLDISMC_QTHOLD1)  [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 4]
    set pktfmt(P_SETTINGS_OLDISMC_QTHOLD2)  [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 5]
    set pktfmt(P_SETTINGS_OLDISMC_QTIMEOUT) [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 6]
    set pktfmt(P_SETTINGS_OLDISMC_QPENALTY) [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 7]
    set pktfmt(P_SETTINGS_OLDISMC_RUPINT)   [expr $pktfmt(P_SETTINGS_OLDISMC_START) + 8]


    set pktfmt(PB_SETFEEDBACK_START)	   [expr $start + ($pktfmt(PACKET_DATA_LENGTH) - 2)]
    set pktfmt(PB_SETFEEDBACK_SETVER)      [expr $pktfmt(PB_SETFEEDBACK_START)+0]
    set pktfmt(PB_SETFEEDBACK_PROGVER)     [expr $pktfmt(PB_SETFEEDBACK_START)+1]

    set pktfmt(PB_SETFEEDBACK_STD_START)   [expr $pktfmt(PB_SETFEEDBACK_START) - 2]
    set pktfmt(PB_SETFEEDBACK_STD_TXRES)   [expr $pktfmt(PB_SETFEEDBACK_STD_START)+0]
    set pktfmt(PB_SETFEEDBACK_STD_TXRATE)  [expr $pktfmt(PB_SETFEEDBACK_STD_START)+1]

    set pktfmt(PB_SETFEEDBACK_SYNC_START) 	[expr $pktfmt(PB_SETFEEDBACK_START) - 12]
    set pktfmt(PB_SETFEEDBACK_SYNC_TTIME) 	[expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+0]
    set pktfmt(PB_SETFEEDBACK_SYNC_RXCNT) 	[expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+1]
    set pktfmt(PB_SETFEEDBACK_SYNC_TXCNT) 	[expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+3]
    set pktfmt(PB_SETFEEDBACK_SYNC_NODEATTR) 	[expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+5]
    set pktfmt(PB_SETFEEDBACK_SYNC_PTX)         [expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+6]
    set pktfmt(PB_SETFEEDBACK_SYNC_PRX)         [expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+7]
    set pktfmt(PB_SETFEEDBACK_SYNC_PSAVE)       [expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+8]
    set pktfmt(PB_SETFEEDBACK_SYNC_PCPU)        [expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+9]
    set pktfmt(PB_SETFEEDBACK_SYNC_METRIC)      [expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+10]
    set pktfmt(PB_SETFEEDBACK_SYNC_TXRES)   	[expr $pktfmt(PB_SETFEEDBACK_SYNC_START)+11]

    set pktfmt(PB_SETFEEDBACK_ISMC_START)       [expr $pktfmt(PB_SETFEEDBACK_START) - 2]
    set pktfmt(PB_SETFEEDBACK_ISMC_SETVER)      [expr $pktfmt(PB_SETFEEDBACK_ISMC_START)+0]
    set pktfmt(PB_SETFEEDBACK_ISMC_PROGVER)     [expr $pktfmt(PB_SETFEEDBACK_ISMC_START)+1]
    set pktfmt(PB_SETFEEDBACK_ISMC_TXRES)       [expr $pktfmt(PB_SETFEEDBACK_ISMC_START)+2]
    set pktfmt(PB_SETFEEDBACK_ISMC_TXRATE)      [expr $pktfmt(PB_SETFEEDBACK_ISMC_START)+3]




    set pktfmt(PD_PAYLD_TOTALSIZE) [expr $pktfmt(P_PGYBACK) - $pktfmt(P_PAYLD) + 1]

    set pktfmt(PD_CONTENT)             0

    set pktfmt(PD_DATANAME_LEN)        1
    set pktfmt(PD_DATANAME) 	       2
    set pktfmt(PD_DATANAME_MAXLENGTH)  6

    set pktfmt(PD_DATAVAL)      [expr $pktfmt(PD_DATANAME) + $pktfmt(PD_DATANAME_MAXLENGTH)]

    set pktfmt(PD_DATAVAL_MOTION)   0
    set pktfmt(PD_DATAVAL_EXTRA)    1
    set pktfmt(PD_DATAVAL_TEMP)     3
    set pktfmt(PD_DATAVAL_VOLTAGE)  5
    set pktfmt(PD_DATAVAL_CURRENT)  7



    set pktfmt(PD_NODETYPE)  	1
    set pktfmt(PD_NBRCNT)      	2
    set pktfmt(PD_NBRLIST)     	3
    set pktfmt(PD_NBRLIST_MAXCNT) [expr $pktfmt(PD_PAYLD_TOTALSIZE) - 4]

    set pktfmt(PD_TR_HOPCOUNT)  1
    set pktfmt(PD_TR_HOPLIST)   2
    set pktfmt(PD_TR_MAXHOPS_VOTE)   [expr ($pktfmt(P_VOTE_START1)-$pktfmt(P_PAYLD)) - 2]
    set pktfmt(PD_TR_MAXHOPS)   [expr ($pktfmt(P_VOTE_START1)-$pktfmt(P_PAYLD)) - 2]
    #set pktfmt(PD_TR_MAXHOPS)   [expr $pktfmt(PD_PAYLD_TOTALSIZE) - 3]

    set pktfmt(PD_TR_MAXHOPS_SYNC)   [expr ($pktfmt(PB_SETFEEDBACK_SYNC_START)-$pktfmt(P_PAYLD))-2]

    set pktfmt(PD_SYNCSTATS_HOPCOUNT)		1
    set pktfmt(PD_SYNCSTATS_FCACHE_DROPCNT)	2
    set pktfmt(PD_SYNCSTATS_TXFAILCNT)		4
    set pktfmt(PD_SYNCSTATS_SYNC_NBRCNT)	6

    set pktfmt(PD_SYNCSTATS2_TIME_TOTAL)        1
    set pktfmt(PD_SYNCSTATS2_TIME_TX)           5
    set pktfmt(PD_SYNCSTATS2_TIME_CPU)          9
    set pktfmt(PD_SYNCSTATS2_TIME_RX)           13
    set pktfmt(PD_SYNCSTATS2_TIME_SAVE)         17

    set pktfmt(PD_SYNCSTATS3_TIME_TXDATA)        1
    set pktfmt(PD_SYNCSTATS3_TIME_RXDATA)        5
    set pktfmt(PD_SYNCSTATS3_DATA_TOTNBRCNT)     9
    set pktfmt(PD_SYNCSTATS3_DATA_ACTNBRCNT)     10
    set pktfmt(PD_SYNCSTATS3_TIME_RELAY)         11
    set pktfmt(PD_SYNCSTATS3_HELLO_RXCNT)        13
    set pktfmt(PD_SYNCSTATS3_HELLO_TXCNT)        15

    set pktfmt(PD_DV_DEST)       1
    set pktfmt(PD_DV_NEXTHOP)    2
    set pktfmt(PD_DV_DESTSEQ)    3
    set pktfmt(PD_DV_DESTHOPCNT) 4


    set pktfmt(PD_VOTEDATA_NUM_CATS) 1
    set pktfmt(PD_VOTEDATA_FIRST)    2
    set pktfmt(PD_VOTEDATA_MAXCATS)  6

    set pktfmt(T_HELLO) 		60
    set pktfmt(T_FLOOD) 		61
    set pktfmt(T_DSDV)	 	        62
    set pktfmt(T_DSDV_RUPDATE)  	63
    set pktfmt(T_OBJECT)  	        64
    set pktfmt(T_RELAYORG2)  	        65
    set pktfmt(T_DSDV_RUPDATE_REQ)  	67
    set pktfmt(T_NBRSTATS)  	        68

    set pktfmt(C_VOTE_TRACEROUTE)       49
    set pktfmt(C_NBRLIST) 		50
    set pktfmt(C_OCCUPANCY_STATE) 	51
    set pktfmt(C_NODENAME)  	        52
    set pktfmt(C_TRACEROUTE) 		53
    set pktfmt(C_SLEEPCMD) 		54
    set pktfmt(C_DSDV_RUPDATE) 	        56
    set pktfmt(C_TEMPERATURE) 	        57
    set pktfmt(C_VOTEDATA) 	        58
    set pktfmt(C_VOTECTL) 	        59

    set pktfmt(C_ECHO_REQUEST)	       	60
    set pktfmt(C_ECHO_REPLY)	       	61

    set pktfmt(C_TRACEROUTE_SYNC)	70
    set pktfmt(C_SYNCSTATS)		71
    set pktfmt(C_SYNCSTATS2)		72
    set pktfmt(C_SYNCSTATS3)		73

    set pktfmt(C_TESTDSDV) 		b0

    set pktfmt(C_TESTSOFTUART) 		ba
    set pktfmt(C_TESTGATES) 		bb

    set pktfmt(T_SETTINGS)		29
    set pktfmt(C_SETTINGS)		29
    set pktfmt(C_SETTINGS_OLDISMC)	28
    set pktfmt(C_SETTINGS_SYNC)		27


    #set pktfmt(SYNC_DSCVRY)   c0
    set pktfmt(SYNC_CNTRL_DSC) 80
    set pktfmt(SYNC_SOLICIT)   40
    set pktfmt(SYNC_INFO)      00

    set pktfmt(SYNC_CTRLMASK) c0
    set pktfmt(SYNC_LVLMASK)  30

    set pktfmt(SYNC_SLEVEL0)  00
    set pktfmt(SYNC_SLEVEL1)  10
    set pktfmt(SYNC_SLEVEL2)  20

    set pktfmt(SYNC_PKTSIZE)  6
}


proc check_for_synch_packet {bytes} {
    global pktfmt
    set all_zeros 1

    set start 0
    set end [expr $start + $pktfmt(PACKET_DATA_LENGTH)]

    for {set i [expr $start + 6]} {$i < $end} {incr i} {
	if {[lindex $bytes $i] != "00"} {
	    set all_zeros 0
	    break
	}
    }
    return $all_zeros
}

proc parse_packet {pktstr packetName} {
    global pktfmt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar $packetName packet

    set bytes [split $pktstr " "]

    #puts "received: $bytes"

    set packet(printall) 1

    set packet(time) [clock format [clock seconds] -format "%H:%M:%S"]


    #Check for SYNCH intent message -- 6 bytes followed by all zeros
    if {$pktfmt(nesc) == 0  &&  [check_for_synch_packet $bytes] > 0} {
	set packet(synchpkt) 1
	for {set i 0} {$i < 6} {incr i} {
	    set packet(synch,$i) [lindex $bytes $i]
	}

	set packet(synch,type) [format "%02x" [expr 0x$packet(synch,0) & 0xc0]]
	set packet(synch,seq)  [format "%3d" [expr 0x$packet(synch,0) & 0x0f]]
	set packet(synch,sndr) [format "%3d" 0x$packet(synch,1)]
	#set packet(synch,dscvry_seq) [format "%3d" 0x$packet(synch,2)]
	#set packet(synch,global_mode) [expr 0x$packet(synch,3) & 0xff]
	set packet(synch,time) [format "%5d" [expr 0x$packet(synch,2) + (256 * 0x$packet(synch,3))]]
	set packet(synch,time_est) [format "%3.2f" [expr ($packet(synch,time) / 512.0) * 2.0]]
	#set packet(synch,time_est) [format "%3.2f" [expr ($packet(synch,time) / 512.0) * 1.5]]
	
	set packet(amtype) -1

	return 1
    }

    set packet(synchpkt) 0
    



    set packet(amtype) [format "%d" 0x[lindex $bytes 2]]

    if {$packet(amtype) == 49} {
	#this is related to network programming
	# for now, just parse out nodeid info
	
	set code0 [lindex $bytes 4]
	set code1 [lindex $bytes 5]
	set code2 [lindex $bytes 6]
	set code3 [lindex $bytes 7]

	if {[string tolower $code2] == "c0"  &&  [string tolower $code3] == "7f"} {
	    set id0 [format "%d" 0x[lindex $bytes 8]]
	    set id1 [format "%d" 0x[lindex $bytes 9]]
	    set packet(prog,moteid) [expr $id0 + ($id1 * 256)]

	    set id0 [format "%d" 0x[lindex $bytes 10]]
	    set id1 [format "%d" 0x[lindex $bytes 11]]
	    set packet(prog,nextprogid) [expr $id0 + ($id1 * 256)]

	    set id0 [format "%d" 0x[lindex $bytes 12]]
	    set id1 [format "%d" 0x[lindex $bytes 13]]
	    set packet(prog,nextprogsize) [expr $id0 + ($id1 * 256)]
	}

	return -1
    } elseif {[lsearch $pktfmt(amvalid) $packet(amtype)] < 0} {
	puts "dropping invalid AM packet: $packet(amtype) -- not in $pktfmt(amvalid)"
	return -1;
    }


    set packet(sndr) [format "%3d" 0x[lindex $bytes $pktfmt(P_SNDR)]]
    set packet(seq)  [format "%3d" 0x[lindex $bytes $pktfmt(P_SEQ)]]
    set packet(type) [lindex $bytes $pktfmt(P_TYPE)]

    if {$pktfmt(nesc) == 1} {
	set packet(len) [format "%3d" 0x[lindex $bytes $pktfmt(P_LEN)]]
    }

    set packet(setval,included) 0
    set packet(setval,std,included) 0
    set packet(setval,sync,included) 0

    #Disable printing log info for now
    set packet(printlog) 0

    set packet(log,valid) 0

    #    for {set i 0} {$i < 6} {incr i} {
    #	set val [lindex $bytes [expr $pktfmt(P_PGYBACK) + $i]]
    #	set packet(loglist) [lappend packet(loglist) $val]
    #	set packet(log,[expr $i + 1]) $val
    #	if {$val > 0} {
    #	    set packet(log,valid) 1
    #	}
    #    }
    #    set packet(logliststr) [join $packet(loglist) " "]
    #    set packet(log,addr) [format "%3d" 0x$packet(log,1)]
    #    set packet(log,val) [format "%3d" 0x$packet(log,2)]
    #    set packet(log,t1) [expr (0x$packet(log,4) & 0x80) >> 6]
    #    set packet(log,t2) [expr (0x$packet(log,6) & 0x80) >> 7]
    #    set packet(log,type) [expr $packet(log,t1) + $packet(log,t2)]
    #    set packet(log,utime) [format "%04x" [expr ((0x$packet(log,4) & 0x7f)<<8) + 0x$packet(log,3)]]
    #    set packet(log,ntime) [format "%04x" [expr ((0x$packet(log,6) & 0x7f)<<8) + 0x$packet(log,5)]]

    if {$pktfmt(nesc) == 0} {
        set packet(settings,vote1) [format "%02x" 0x[lindex $bytes $pktfmt(P_VOTE_START1)]]
        set packet(settings,vote2) [format "%02x" 0x[lindex $bytes $pktfmt(P_VOTE_START2)]]
        set packet(settings,vote3) [format "%02x" 0x[lindex $bytes $pktfmt(P_VOTE_START3)]]
        set packet(settings,vote4) [format "%02x" 0x[lindex $bytes $pktfmt(P_VOTE_START4)]]
    }

    if {$pktfmt(nesc) == 0 && $packet(type) == $pktfmt(T_HELLO)} {
	parse_org_packet $bytes $packetName
    } elseif {$pktfmt(nesc) == 0 && $packet(type) == $pktfmt(T_RELAYORG2)} {
	parse_relayorg2_packet $bytes $packetName
    } elseif {$packet(type) == $pktfmt(T_DSDV_RUPDATE_HOPS) || $packet(type) == $pktfmt(T_DSDV_RUPDATE_QUALITY) || $packet(type) == $pktfmt(T_DSDV_RUPDATE_SOI)} {
	parse_rupdate_packet $bytes $packetName
    } elseif {$pktfmt(nesc) == 0 && $packet(type) == $pktfmt(T_NBRSTATS)} {
	parse_nbrstats_packet $bytes $packetName
    } elseif {$packet(type) == $pktfmt(T_FLOOD)} {
	parse_mhop_packet $bytes $packetName
    } elseif {$packet(type) == $pktfmt(T_DSDV)} {
	parse_mhop_packet $bytes $packetName
    } elseif {$packet(type) == $pktfmt(T_DSDV_SOI)} {
	parse_mhop_packet $bytes $packetName
    } else {
	return -1
    }

    return 1
}


proc parse_rupdate_packet {bytes packetName} {
    global pktfmt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar 2 $packetName packet

    set found 0
    foreach type [list $pktfmt(T_DSDV_RUPDATE_HOPS) $pktfmt(T_DSDV_RUPDATE_QUALITY) $pktfmt(T_DSDV_RUPDATE_SOI)] {
	if {$packet(type) == $type} {
	    set found 1
	}
    }
    if {$found == 0} {
	return -1
    }

    set packet(addr) [format "%3d" 0x[lindex $bytes $pktfmt(P_SNDR)]]

    if {$packet(type) != $pktfmt(T_DSDV_RUPDATE_SOI)} {
	set packet(dru_dest) [format "%d" 0x[lindex $bytes $pktfmt(P_DRU_DEST)]]
	set packet(dru_seq) [format "%d" 0x[lindex $bytes $pktfmt(P_DRU_SEQ)]]
	set byte1 [format "%d" 0x[lindex $bytes $pktfmt(P_DRU_COST)]]
	set byte2 [format "%d" 0x[lindex $bytes [expr $pktfmt(P_DRU_COST)+1]]]
	set packet(dru_hop) [format "%d" [expr $byte1 + ($byte2<<8)]] 
	set packet(dru_sender) [format "%d" 0x[lindex $bytes $pktfmt(P_DRU_SENDER)]]
	set qpiggyback $pktfmt(P_DRU_PAYLD)
    } else {
	set packet(soiru_dest)   [format "%d" 0x[lindex $bytes $pktfmt(P_SOIRU_DEST)]]
	set packet(soiru_seq)    [format "%d" 0x[lindex $bytes $pktfmt(P_SOIRU_SEQ)]]
	set packet(soiru_id1)    [format "%3d" 0x[lindex $bytes $pktfmt(P_SOIRU_ID1)]]
	set byte1 [format "%d" 0x[lindex $bytes $pktfmt(P_SOIRU_FC1)]]
	set byte2 [format "%d" 0x[lindex $bytes [expr $pktfmt(P_SOIRU_FC1)+1]]]
	set packet(soiru_fc1) [format "%3d" 0x[expr $byte1 + ($byte2<<8)]] 
	set byte1 [format "%d" 0x[lindex $bytes $pktfmt(P_SOIRU_VC1)]]
	set byte2 [format "%d" 0x[lindex $bytes [expr $pktfmt(P_SOIRU_VC1)+1]]]
	set packet(soiru_vc1) [format "%3d" 0x[expr $byte1 + ($byte2<<8)]] 
	set packet(soiru_id2)    [format "%3d" 0x[lindex $bytes $pktfmt(P_SOIRU_ID2)]]
	set byte1 [format "%d" 0x[lindex $bytes $pktfmt(P_SOIRU_FC2)]]
	set byte2 [format "%d" 0x[lindex $bytes [expr $pktfmt(P_SOIRU_FC2)+1]]]
	set packet(soiru_fc2) [format "%3d" 0x[expr $byte1 + ($byte2<<8)]] 
	set byte1 [format "%d" 0x[lindex $bytes $pktfmt(P_SOIRU_VC2)]]
	set byte2 [format "%d" 0x[lindex $bytes [expr $pktfmt(P_SOIRU_VC2)+1]]]
	set packet(soiru_vc2) [format "%3d" 0x[expr $byte1 + ($byte2<<8)]] 
	set qpiggyback $pktfmt(P_SOIRU_PAYLD)
    }

    set numthr 3
    set pos [expr $qpiggyback + $numthr + 1]
    for {set th 0} {$th <= $numthr} {incr th} {
	set th_cnt [format "%d" 0x[lindex $bytes [expr $qpiggyback+$th]]]
	set th_val [expr $numthr - $th]
	set packet(nbr,th${th_val},cnt) $th_cnt
	for {set i 0} {$i < $th_cnt} {incr i} {
	    set packet(nbr,th${th_val},$i) [format "%d" 0x[lindex $bytes $pos]]
	    incr pos
	}
    }

    set packet(nbrlist) ""
    if {$pktfmt(nesc) == 0} {
	for {set i 0} {$i < $pktfmt(P_DRU_PAYLD_TOTALSIZE)} {incr i} {
	    set packet(nbrlist) [append packet(nbrlist) " [format "%d" 0x[lindex $bytes [expr $pktfmt(P_DRU_PAYLD)+$i]]]"]
	}
    }

    return 1
}


proc parse_nbrstats_packet {bytes packetName} {
    global pktfmt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar 2 $packetName packet

    if {$packet(type) != $pktfmt(T_NBRSTATS)} {
	return -1
    }

    set packet(nbrstats,cnt) [format "%d" 0x[lindex $bytes $pktfmt(P_NBRSTATS_PAYLD)]]
    set maxcnt [expr floor($pktfmt(P_NBRSTATS_PAYLD) / 2)]
    if {$packet(nbrstats,cnt) > $maxcnt} {
	set packet(nbrstats,cnt) $maxcnt
    }

    set pos [expr $pktfmt(P_NBRSTATS_PAYLD) + 1]
    for {set i 0} {$i < $packet(nbrstats,cnt)} {incr i} {
	set packet(nbrstats,$i,addr) [format "%d" 0x[lindex $bytes $pos]]
	incr pos
	set packet(nbrstats,$i,stat) [format "%d" 0x[lindex $bytes $pos]]
	incr pos
    }

    set packet(nbrlist) ""
    for {set i 0} {$i < $pktfmt(P_NBRSTATS_PAYLD_TOTALSIZE)} {incr i} {
	set packet(nbrlist) [append packet(nbrlist) " [format "%d" 0x[lindex $bytes [expr $pktfmt(P_NBRSTATS_PAYLD)+$i]]]"]
    }

    return 1
}



proc parse_org_packet {bytes packetName} {
    global pktfmt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar 2 $packetName packet

    if {$packet(type) != $pktfmt(T_HELLO)} {
	return -1
    }

    set packet(addr) [format "%3d" 0x[lindex $bytes $pktfmt(P_SNDR)]]
    set packet(metric) [lindex $bytes $pktfmt(P_METRIC)]
    set packet(relay) [format "%d" 0x[lindex $bytes $pktfmt(P_RELAY)]]
    set packet(relaycnt) [format "%d" 0x[lindex $bytes $pktfmt(P_RNBRCNT)]]
    set packet(nbrcnt) [format "%d" 0x[lindex $bytes $pktfmt(P_NBRCNT)]]
    set packet(relaylist) ""
    set packet(nbrlist) ""
    set packet(nbrlist_norelays) ""
    
    for {set i 0} {$i < $packet(nbrcnt)} {incr i} {
	if {$i < $packet(relaycnt)} {
	    set packet(relaylist) [lappend packet(relaylist) "[format "%d" 0x[lindex $bytes [expr $pktfmt(P_NBRLST)+$i]]]"]
	} else {
	    set packet(nbrlist_norelays) [lappend packet(nbrlist_norelays) "[format "%d" 0x[lindex $bytes [expr $pktfmt(P_NBRLST)+$i]]]"]
	}
	set packet(nbrlist) [lappend packet(nbrlist) "[format "%d" 0x[lindex $bytes [expr $pktfmt(P_NBRLST)+$i]]]"]
    }

    set packet(relayliststr) [join [lsort -integer $packet(relaylist)] " "]
    set packet(nbrliststr) [join [lsort -integer $packet(nbrlist)] " "]
    set packet(nbrlist_norelaystr) [join [lsort -integer $packet(nbrlist_norelays)] " "]
    if {$packet(relaycnt) > 0} {
	set tmpstr "{$packet(relayliststr)} $packet(nbrlist_norelaystr)"
    } else {
	set tmpstr "$packet(nbrliststr)"
    }

    for {set i 0} {$i < $packet(nbrcnt)} {incr i} {
	set packet(nbr,$i) [lindex $i $tmpstr]
    }
    
    return 1
}



proc parse_relayorg2_packet {bytes packetName} {
    global pktfmt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar 2 $packetName packet

    if {$packet(type) != $pktfmt(T_RELAYORG2)} {
	return -1
    }

    #puts "parsing relayorg2..."

    set packet(addr)      [format "%3d" 0x[lindex $bytes $pktfmt(P_SNDR)]]
    set packet(ro,seq)    [format "%3d" 0x[lindex $bytes $pktfmt(P_RO_SEQ)]]
    set packet(ro,metric)    [format "%3d" 0x[lindex $bytes $pktfmt(P_RO_METRIC)]]
    set packet(ro,state)     [format "%3d" 0x[lindex $bytes $pktfmt(P_RO_STATE)]]
    set packet(ro,mypr)      [format "%3d" 0x[lindex $bytes $pktfmt(P_RO_MYPR)]]
    set packet(ro,mypr_hex)  [format "%02x" 0x[lindex $bytes $pktfmt(P_RO_MYPR)]]
    set packet(ro,prncnt)    [format "%d" 0x[lindex $bytes $pktfmt(P_RO_PRNCNT)]]
    set packet(ro,prnlist)   ""
    

    #puts "state: $packet(ro,state)"

    set mode [expr ($packet(ro,state) & 0xc0)>>6]
    set packet(ro,statestr) [switch $mode {
	1 {format PR}
	2 {format SR}
	3 {format ??}
	default {format --}
    }]


    set packet(ro,prnliststr) ""
    for {set i 0} {$i < $packet(ro,prncnt)} {incr i} {
 	set nodeaddr "[format "%3d" 0x[lindex $bytes [expr $pktfmt(P_RO_PRNLST)+(2*$i)]]]"
 	set nodeattr "[format "%3d" 0x[lindex $bytes [expr $pktfmt(P_RO_PRNLST)+(2*$i)+1]]]"

	#puts "nodeaddr: $nodeaddr"
	#puts "nodeattr: $nodeattr"
	
 	set mode [expr ($nodeattr & 0xc0) >> 6]
  	set conn [expr ($nodeattr & 0x30) >> 4]
 	set seqn [format "%2d" [expr ($nodeattr & 0x0f)]]
 	
 	set modestr [switch $mode {
 	    1 {format PR}
 	    2 {format SR}
 	    3 {format st}
 	    default {format NR}
 	}]

	set connstr [switch $conn {
	    1 {format I}
	    2 {format D}
	    3 {format ?}
	    default {format N}
	}]

	#puts "State: $nodeattr ==> $mode $conn $seqn"
	
	set packet(ro,prnlist,$i,addr) $nodeaddr
	set packet(ro,prnlist,$i,mode) $modestr
	set packet(ro,prnlist,$i,conn) $connstr
	set packet(ro,prnlist,$i,seqn) $seqn

	set packet(ro,prnliststr) [append prnliststr "[fmtaddr $nodeaddr]($modestr $connstr $seqn) "]
    }

    #puts "done parse"
    
    return 1
}



proc parse_mhop_packet {bytes packetName} {
    global pktfmt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar 2 $packetName packet

    if {($packet(type) != $pktfmt(T_FLOOD))  &&  ($packet(type) != $pktfmt(T_DSDV))  &&  ($packet(type) != $pktfmt(T_DSDV_SOI))} {
	return -1
    }

    if {$pktfmt(nesc) == 1} {
	set packet(pgyback) ""

	#adjust location of adjuvant bits based on dynamic packet size
	#starts from 0 in TraceRoute header, assume it's SoI packet, which
	#has 1 byte sphere id after singlehop header, and 
	#settings feeback 1 byte, adjuvant node bits 2 bytes from tail
	set pktfmt(TR_OFFSET_SOI_ADJBITS) [expr $packet(len) - 12]
	set pktfmt(TR_OFFSET_SOI_SETFB)   [expr $packet(len) - 10]

	if {$packet(type) == $pktfmt(T_DSDV_SOI)} {
	    set packet(mhopsndr) [format "%3d" 0x[lindex $bytes $pktfmt(P_SOI_MHOPSNDR)]]
	    set packet(mhopdest) [format "%3d" 0x[lindex $bytes $pktfmt(P_SOI_MHOPDEST)]]
	    set packet(mhopapp)  [format "%3d" 0x[lindex $bytes $pktfmt(P_SOI_MHOPAPP)]]
	    set packet(mhoplen)  [format "%3d" 0x[lindex $bytes $pktfmt(P_SOI_MHOPLEN)]]
	} else {
	    set packet(mhopsndr) [format "%3d" 0x[lindex $bytes $pktfmt(P_MHOPSNDR)]]
	    set packet(mhopdest) [format "%3d" 0x[lindex $bytes $pktfmt(P_MHOPDEST)]]
	    set packet(mhopapp)  [format "%3d" 0x[lindex $bytes $pktfmt(P_MHOPAPP)]]
	    set packet(mhoplen)  [format "%3d" 0x[lindex $bytes $pktfmt(P_MHOPLEN)]]
	}

	if {$packet(type) == $pktfmt(T_FLOOD)} {
	    set packet(floodseq) [format "%3d" 0x[lindex $bytes $pktfmt(P_FLOODSEQ)]]
	    set packet(floodttl) [format "%2d" 0x[lindex $bytes $pktfmt(P_FLOODTTL)]]
	    set datastart $pktfmt(P_FLOODDATA)
	} else {
	    if {$packet(type) == $pktfmt(T_DSDV_SOI)} {
		set packet(soi_sphereid) [format "%3d" 0x[lindex $bytes $pktfmt(P_SOI_SPHEREID)]]
		set packet(soi_dsdvnext) [format "%3d" 0x[lindex $bytes $pktfmt(P_SOI_DSDVNEXT)]]
		set packet(soi_dsdvseq)  [format "%3d" 0x[lindex $bytes $pktfmt(P_SOI_DSDVSEQ)]]
		set packet(soi_dsdvttl)  [format "%2d" 0x[lindex $bytes $pktfmt(P_SOI_DSDVTTL)]]
		set datastart $pktfmt(P_SOI_DSDVDATA)
	    } else {
		set packet(dsdvnext) [format "%3d" 0x[lindex $bytes $pktfmt(P_DSDVNEXT)]]
		set packet(dsdvseq)  [format "%3d" 0x[lindex $bytes $pktfmt(P_DSDVSEQ)]]
		set packet(dsdvttl)  [format "%2d" 0x[lindex $bytes $pktfmt(P_DSDVTTL)]]
		set datastart $pktfmt(P_DSDVDATA)
	    }
	}

	set packet(mhoppayload) ""
	for {set i 0} {$i < $packet(mhoplen)} {incr i} {
	    set packet(mhoppayload) "$packet(mhoppayload) [lindex $bytes [expr $datastart + $i]]"
	}
	
	if {$packet(mhopapp) == $pktfmt(C_TRACEROUTE)} {
	    set packet(hopcount) [format "%d" 0x[lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_LEN)]]]
	    set packet(maxhopcount) [expr $packet(mhoplen) - ($pktfmt(PGYBACK_LEN_NORMAL) + 1)]
	    
	    set start 0
	    if {$packet(hopcount) > $packet(maxhopcount)} {
		set packet(hop,total) $packet(maxhopcount)
	    } else {
		set packet(hop,total) [expr $packet(hopcount) + 1]
		set packet(hop,0) $packet(mhopsndr)
		set start 1
	    }
	
	    #puts "hoptotal = $packet(hop,total)  hopcount = $packet(hopcount)"
	    for {set i $start} {$i < $packet(hop,total)} {incr i} {
		set packet(hop,$i) [format "%d" 0x[lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_LIST) + [expr $i - $start]]]]
		#puts "hop $i = $packet(hop,$i)"
	    }


	    # Hack Note: need to read energy value from piggyback that is normally used in C_TRACEROUTE_SOI,
	    #   for soimesh demo.
	    set packet(hop,bits1) [lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)]]
	    set packet(hop,bits2) [lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)+1]]
	    set packet(pgyback) [lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_SETFB)+1]]

            set highByte [format "%d" 0x$packet(hop,bits1)]
            set lowByte [format "%d" 0x$packet(hop,bits2)]
	    set packet(energyval) [expr ($highByte<<8) + $lowByte]
	    # Done with Hack

	} elseif {$packet(mhopapp) == $pktfmt(C_TRACEROUTE_SOI)} {
	    set packet(hopcount) [format "%d" 0x[lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_LEN)]]]
	    set packet(maxhopcount) [expr ($pktfmt(TR_OFFSET_SOI_ADJBITS) - $pktfmt(TR_OFFSET_LEN)) - 1]
	    
	    set start 0
	    if {$packet(hopcount) > $packet(maxhopcount)} {
		set packet(hop,total) $packet(maxhopcount)
	    } else {
		set packet(hop,total) [expr $packet(hopcount) + 1]
		set packet(hop,0) $packet(mhopsndr)
		set byte [format "%d" 0x[lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)]]]
		set bit [expr $byte & 0x01]
		set packet(hop,[expr $packet(hop,total)-1],bit) $bit
		set start 1
	    }
	
	    # Hack Note: these two bytes were originally designed for sending adjuvant node status in
	    #   traceroutes, but have since been reused for other purposes.  Since there are no
	    #   packet identifiers to indicate which type of data is stored in these bytes, I will
	    #   just set all of the possible variables here, but only one will have valid data.
	    set packet(hop,bits1) [lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)]]
	    set packet(hop,bits2) [lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)+1]]
	    set packet(energyval) [expr ("0x$packet(hop,bits1)"<<8) + 0x$packet(hop,bits2)]
	    # Done with Hack



	    #puts "hoptotal = $packet(hop,total)  hopcount = $packet(hopcount)  ==> bits: [lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)]]  [lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)+1]]"
	    for {set i $start} {$i < $packet(hop,total)} {incr i} {
		set packet(hop,$i) [format "%d" 0x[lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_LIST) + [expr $i - $start]]]]

		if {$i < 8} {
		    set byte [format "%d" 0x[lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)]]]
		    set bit [expr ($byte >> $i) & 0x01]
		} else {
		    set byte [format "%d" 0x[lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_ADJBITS)+1]]]
		    set bit [expr ($byte >> ($i-8)) & 0x01]
		}
		set packet(hop,[expr ($packet(hop,total)-1) - $i],bit) $bit
	    }

	    lappend packet(pgyback) [lindex $bytes [expr $datastart + $pktfmt(TR_OFFSET_SOI_SETFB)]]
	} elseif {$packet(mhopapp) == $pktfmt(C_SETTINGS)} {
	    set packet(settings) ""
	    for {set i 0} {$i < $packet(mhoplen)} {incr i} {
		append packet(settings) [format "%3d " 0x[lindex $bytes [expr $datastart + $i]]] 
	    }
	}

	#for {set i 0} {$i < $pktfmt(PGYBACK_LEN)} {incr i} {
	#    lappend packet(pgyback) [lindex $bytes [expr $pktfmt(P_PGYBACK) + $i]]
	#}

	return
    }

    set packet(origsndr) [format "%d" 0x[lindex $bytes $pktfmt(P_ORIGSNDR)]]
    set packet(origseq) [format "%3d" 0x[lindex $bytes $pktfmt(P_ORIGSEQ)]]
    set packet(dest) [format "%d" 0x[lindex $bytes $pktfmt(P_DEST)]]
    set packet(nexthop) [format "%d" 0x[lindex $bytes $pktfmt(P_NEXTHOP)]]
    set packet(ttl) [format "%2d" 0x[lindex $bytes $pktfmt(P_TTL)]]

    set packet(content) [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_CONTENT)]]


    # Start by parsing piggyback settings/stats values
    if {$packet(content) == $pktfmt(C_TRACEROUTE) || $packet(content) == $pktfmt(C_VOTE_TRACEROUTE) || $packet(content) == $pktfmt(C_TRACEROUTE_SYNC) || $packet(content) == $pktfmt(C_SYNCSTATS)} {
	set packet(setval,included) 1
	set packet(setval,setver)  [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SETVER)]]
	set packet(setval,progver) [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_PROGVER)]]

	if {$packet(content) == $pktfmt(C_TRACEROUTE)} {
	    set packet(setval,std,included) 1
	    set packet(setval,std,txres)  [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_STD_TXRES)]]
	    set packet(setval,std,txrate) [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_STD_TXRATE)]]
	} elseif {$packet(content) == $pktfmt(C_VOTE_TRACEROUTE)} {
	    set packet(setval,std,included) 1
	    #Note: remap setver and progver, in the future ismc ordering should be changed to match std ordering
	    set packet(setval,setver)       [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_ISMC_SETVER)]]
	    set packet(setval,progver)      [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_ISMC_PROGVER)]]
	    set packet(setval,std,txres)    [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_ISMC_TXRES)]]
	    set packet(setval,std,txrate)   [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_ISMC_TXRATE)]]
	} elseif {$packet(content) == $pktfmt(C_TRACEROUTE_SYNC) || $packet(content) == $pktfmt(C_SYNCSTATS)} {
	    set packet(setval,sync,included) 1

	    set packet(setval,sync,ttime)    [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_TTIME)]]
	    set packet(setval,sync,nodeattr) [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_NODEATTR)]]
	    set packet(setval,sync,ptx)      [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_PTX)]]
	    set packet(setval,sync,prx)      [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_PRX)]]
	    set packet(setval,sync,psave)    [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_PSAVE)]]
	    set packet(setval,sync,pcpu)     [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_PCPU)]]
	    set packet(setval,sync,metric) [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_METRIC)]]
	    set packet(setval,sync,txres)    [format "%3d" 0x[lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_TXRES)]]

	    set txc1 [lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_TXCNT)]
	    set txc2 [lindex $bytes [expr $pktfmt(PB_SETFEEDBACK_SYNC_TXCNT) + 1]]
	    set packet(setval,sync,txcnt) [format "%5d" [expr 0x$txc1 + (256*(0x$txc2))]]

	    set rxc1 [lindex $bytes $pktfmt(PB_SETFEEDBACK_SYNC_RXCNT)]
	    set rxc2 [lindex $bytes [expr $pktfmt(PB_SETFEEDBACK_SYNC_RXCNT) + 1]]
	    set packet(setval,sync,rxcnt) [format "%5d" [expr 0x$rxc1 + (256*(0x$rxc2))]]
	}
    }    


    if {$packet(content) == $pktfmt(C_OCCUPANCY_STATE)} {
	set packet(state) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DATAVAL)]]]

	for {set j 0} {$j < 9} {incr j} {
	    set b($j) [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DATAVAL) + $j]]
	    #puts "b($j) = $b($j)"
	}

	if {$b($pktfmt(PD_DATAVAL_EXTRA)) != 0} {
	    set packet(extra,valid) 1
	    set packet(extra,tempraw) [format "%6d" [expr (0x$b([expr $pktfmt(PD_DATAVAL_TEMP)+1])<<8) + 0x$b($pktfmt(PD_DATAVAL_TEMP))]]
	    set packet(extra,tempraw1) [format "%3d" [expr (0x$b([expr $pktfmt(PD_DATAVAL_TEMP)+1]))]]
	    set packet(extra,tempraw2) [format "%3d" [expr (0x$b($pktfmt(PD_DATAVAL_TEMP)))]]
	    set packet(extra,tempc) [format "%3.3f" [expr ($packet(extra,tempraw)/8.0) * 0.03215]]
	    set packet(extra,tempf) [format "%3.3f" [expr ($packet(extra,tempc)*(9.0/5.0)) + 32.0]]
	    set packet(extra,voltageraw) [format "%6d" [expr (0x$b([expr $pktfmt(PD_DATAVAL_VOLTAGE)+1])<<8) + 0x$b($pktfmt(PD_DATAVAL_VOLTAGE))]]
	    set packet(extra,voltage) [format "%2.2f" [expr $packet(extra,voltageraw) / 100.0]]
	    #set packet(extra,currentraw) [format "%6d" [expr (0x$b([expr $pktfmt(PD_DATAVAL_CURRENT)+1])<<8) + 0x$b($pktfmt(PD_DATAVAL_CURRENT))]]
	    set packet(extra,currentraw) [format "%6hd" "0x$b([expr $pktfmt(PD_DATAVAL_CURRENT)+1])$b($pktfmt(PD_DATAVAL_CURRENT))"]
	    set packet(extra,current) [format "%3.2f" [expr ($packet(extra,currentraw) * 1000.0) / (4096.0 * 1.2)]]
	} else {
	    set packet(extra,valid) 0
	}

	set namelen [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DATANAME_LEN)]]]
	set maxlen [format "%d" 0x$pktfmt(PD_DATANAME_MAXLENGTH)]
	if {$namelen > $maxlen} {
	    set namelen $maxlen
	}
	set name ""
	for {set i 0} {$i<$namelen} {incr i} {
	    set ch [format "%c" 0x[lindex $bytes [expr $i + $pktfmt(P_PAYLD) + $pktfmt(PD_DATANAME)]]]
	    set name "${name}${ch}"
	    #puts "$ch $name"
	}
	set packet(name) $name

    } elseif {$packet(content) == $pktfmt(C_TEMPERATURE)} {
	set packet(printall) 0

	for {set j 0} {$j < 9} {incr j} {
	    set b($j) [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DATAVAL) + $j]]
	    #puts "b($j) = $b($j)"
	}

	if {$b($pktfmt(PD_DATAVAL_EXTRA)) != 0} {
	    set packet(extra,valid) 1
	    set packet(extra,tempraw) [format "%6d" [expr (0x$b([expr $pktfmt(PD_DATAVAL_TEMP)+1])<<8) + 0x$b($pktfmt(PD_DATAVAL_TEMP))]]
	    set packet(extra,tempraw1) [format "%3d" [expr (0x$b([expr $pktfmt(PD_DATAVAL_TEMP)+1]))]]
	    set packet(extra,tempraw2) [format "%3d" [expr (0x$b($pktfmt(PD_DATAVAL_TEMP)))]]
	    set packet(extra,tempc) [format "%3.3f" [expr ($packet(extra,tempraw)/8.0) * 0.03215]]
	    set packet(extra,tempf) [format "%3.3f" [expr ($packet(extra,tempc)*(9.0/5.0)) + 32.0]]
	} else {
	    set packet(extra,valid) 0
	}

	set namelen [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DATANAME_LEN)]]]
	set maxlen [format "%d" 0x$pktfmt(PD_DATANAME_MAXLENGTH)]
	if {$namelen > $maxlen} {
	    set namelen $maxlen
	}
	set name ""
	for {set i 0} {$i<$namelen} {incr i} {
	    set ch [format "%c" 0x[lindex $bytes [expr $i + $pktfmt(P_PAYLD) + $pktfmt(PD_DATANAME)]]]
	    set name "${name}${ch}"
	    #puts "$ch $name"
	}
	set packet(name) $name
    } elseif {$packet(content) == $pktfmt(C_VOTEDATA)} {
	set packet(votedata,numcat) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_VOTEDATA_NUM_CATS)]]]
	if {$packet(votedata,numcat) > $pktfmt(PD_VOTEDATA_MAXCATS)} {
	    set packet(votedata,numcat) $pktfmt(PD_VOTEDATA_MAXCATS)
	}
	for {set i 0} {$i < $packet(votedata,numcat)} {incr i} {
	    set packet(votedata,cat$i) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_VOTEDATA_FIRST) + $i]]]
	}
    } elseif {$packet(content) == $pktfmt(C_NODENAME)} {
	set namelen [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DATANAME_LEN)]]]
	set maxlen [format "%d" 0x$pktfmt(PD_DATANAME_MAXLENGTH)]
	if {$namelen > $maxlen} {
	    set namelen $maxlen
	}
	set name ""
	for {set i 0} {$i<$namelen} {incr i} {
	    set ch [format "%c" 0x[lindex $bytes [expr $i + $pktfmt(P_PAYLD) + $pktfmt(PD_DATANAME)]]]
	    set name "${name}${ch}"
	    #puts "$ch $name"
	}
	set packet(name) $name
    } elseif {$packet(content) == $pktfmt(C_NBRLIST)} {
	set packet(nodetype) [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_NODETYPE)]]

	set packet(nbrcnt) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_NBRCNT)]]]
	set packet(nbrlist) ""
	for {set i 0} {$i < $packet(nbrcnt)} {incr i} {
	    set packet(nbrlist) [lappend packet(nbrlist) "[format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_NBRLIST) + $i]]]"]
	}
	set packet(nbrlist) [lsort -integer $packet(nbrlist)]
	for {set i 0} {$i < $packet(nbrcnt)} {incr i} {
	    set packet(nbr,$i) [lindex $i $packet(nbrlist)]
	}
    } elseif {$packet(content) == $pktfmt(C_TRACEROUTE) || $packet(content) == $pktfmt(C_VOTE_TRACEROUTE) || $packet(content) == $pktfmt(C_TRACEROUTE_SYNC)} {
	set packet(hopcount) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_TR_HOPCOUNT)]]]

	if {$packet(content) == $pktfmt(C_TRACEROUTE_SYNC)} {
	    set packet(maxhopcount) $pktfmt(PD_TR_MAXHOPS_SYNC)
	} elseif {$packet(content) == $pktfmt(C_VOTE_TRACEROUTE)} {
	    set packet(maxhopcount) $pktfmt(PD_TR_MAXHOPS_VOTE)
	} else {
	    set packet(maxhopcount) $pktfmt(PD_TR_MAXHOPS)
	}

	if {$packet(hopcount) > $packet(maxhopcount)} {
	    set packet(hop,total) $packet(maxhopcount)
	} else {
	    set packet(hop,total) $packet(hopcount)
	}
	
	for {set i 0} {$i < $packet(hop,total)} {incr i} {
	    set packet(hop,$i) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_TR_HOPLIST) + $i]]]
	}
    } elseif {$packet(content) == $pktfmt(C_SYNCSTATS)} {
	set packet(syncstats,hopcount) [format "%2d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS_HOPCOUNT)]]]

	set c1 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS_FCACHE_DROPCNT)]]
	set c2 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS_FCACHE_DROPCNT) + 1]]
	set packet(syncstats,fcachedropcnt) [format "%5d" [expr 0x$c1 + (256*(0x$c2))]]

	set c1 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS_TXFAILCNT)]]
	set c2 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS_TXFAILCNT) + 1]]
	set packet(syncstats,txfailcnt) [format "%5d" [expr 0x$c1 + (256*(0x$c2))]]

	set packet(syncstats,syncnbrcnt) [format "%2d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS_SYNC_NBRCNT)]]]
    } elseif {$packet(content) == $pktfmt(C_SYNCSTATS2)} {
	set index $pktfmt(PD_SYNCSTATS2_TIME_TOTAL)
	for {set j 0} {$j<5} {incr j} {
	    set temp 0
	    for {set i 0} {$i<4} {incr i} {
		set b 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $index + $i]]
		incr temp [expr $b * int(pow(256,$i))]
		#puts "$j $i ==> $b $temp"
	    }
	    set val($j) $temp
	    incr index 4
	}
	set packet(syncstats2,time_total) [format "%10d" $val(0)]
	set packet(syncstats2,time_tx)    [format "%10d" $val(1)]
	set packet(syncstats2,time_cpu)   [format "%10d" $val(2)]
	set packet(syncstats2,time_rx)    [format "%10d" $val(3)]
	set packet(syncstats2,time_save)  [format "%10d" $val(4)]

	if {$packet(syncstats2,time_total) != 0} {
	    set packet(syncstats2,ptx)   [format "%3.3f" [expr (double($packet(syncstats2,time_tx)) / double($packet(syncstats2,time_total))) * 100.0]]
	    set packet(syncstats2,prx)   [format "%3.3f" [expr (double($packet(syncstats2,time_rx)) / double($packet(syncstats2,time_total))) * 100.0]]
	    set packet(syncstats2,pcpu)  [format "%3.3f" [expr (double($packet(syncstats2,time_cpu)) / double($packet(syncstats2,time_total))) * 100.0]]
	    set packet(syncstats2,psave) [format "%3.3f" [expr (double($packet(syncstats2,time_save)) / double($packet(syncstats2,time_total))) * 100.0]]
	} else {
	    set packet(syncstats2,ptx) "100.0"
	    set packet(syncstats2,prx) "100.0"
	    set packet(syncstats2,pcpu) "100.0"
	    set packet(syncstats2,psave) "100.0"
	}
    } elseif {$packet(content) == $pktfmt(C_SYNCSTATS3)} {
	set index $pktfmt(PD_SYNCSTATS3_TIME_TXDATA)
	for {set j 0} {$j<2} {incr j} {
	    set temp 0
	    for {set i 0} {$i<4} {incr i} {
		set b 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $index + $i]]
		incr temp [expr $b * int(pow(256,$i))]
		#puts "$j $i ==> $b $temp"
	    }
	    set val($j) $temp
	    incr index 4
	}
	set packet(syncstats3,time_txdata) [format "%10d" $val(0)]
	set packet(syncstats3,time_rxdata) [format "%10d" $val(1)]

	set tr1 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS3_TIME_RELAY)]]
	set tr2 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS3_TIME_RELAY) + 1]]
	set packet(syncstats3,time_relay) [format "%5d" [expr 0x$tr1 + (256*(0x$tr2))]]

	if {![info exists packet(syncstats2,time_total)]} {
	    set packet(syncstats2,time_total) 0
	}

	# Note: can't compute these here because time_total is not included in syncstats3 packets
	#if {$packet(syncstats2,time_total) != 0} {
	#    set packet(syncstats3,ptxdata)   [format "%3.3f" [expr (double($packet(syncstats3,time_txdata)) / double($packet(syncstats2,time_total))) * 100.0]]
	#    set packet(syncstats3,prxdata)   [format "%3.3f" [expr (double($packet(syncstats3,time_rxdata)) / double($packet(syncstats2,time_total))) * 100.0]]
	#    set packet(syncstats3,prelay)   [format "%3.3f" [expr (double($node(syncstats3,time_relay) * 60 * 244) / double($packet(syncstats2,time_total))) * 100.0]]
	#} else {
	    set packet(syncstats3,ptxdata) "   XX"
	    set packet(syncstats3,prxdata) "   XX"
	    set packet(syncstats3,prelay)  "   XX"
	#}

	set packet(syncstats3,data_totnbrcnt) [format "%3d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS3_DATA_TOTNBRCNT)]]]
	set packet(syncstats3,data_actnbrcnt) [format "%3d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS3_DATA_ACTNBRCNT)]]]

	set rx1 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS3_HELLO_RXCNT)]]
	set rx2 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS3_HELLO_RXCNT) + 1]]
	set packet(syncstats3,hello_rxcnt) [format "%5d" [expr 0x$rx1 + (256*(0x$rx2))]]

	set tx1 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS3_HELLO_TXCNT)]]
	set tx2 [lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_SYNCSTATS3_HELLO_TXCNT) + 1]]
	set packet(syncstats3,hello_txcnt) [format "%5d" [expr 0x$tx1 + (256*(0x$tx2))]]

    } elseif {$packet(content) == $pktfmt(C_TESTSOFTUART)} {
	set packet(printall) 0
	set packet(test,count) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + 1]]]
	if {$packet(test,count) < 8} {
	    set cnt $packet(test,count)
	} else {
	    set cnt 7
	}

	set packet(test,list) ""
	for {set j 0} {$j < $cnt} {incr j} {
	    set packet(test,list) [lappend packet(test,list) "[format "%3d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + 2 + (2*$j)]]] [format "%3d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + 2 + (2*$j)+1]]]"]
	}
    } elseif {$packet(content) == $pktfmt(C_TESTGATES)} {
	set packet(printall) 0
	set packet(test,count) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + 1]]]
	if {$packet(test,count) <= 18} {
	    set cnt $packet(test,count)
	} else {
	    set cnt 18
	}

	set packet(test,list) ""
	set packet(test,list2) ""
	for {set j 0} {$j < $cnt} {incr j} {
	    set val [lindex $bytes [expr $pktfmt(P_PAYLD) + 2 + $j]]
	    set packet(test,list) "$packet(test,list)  [format "%3d" 0x${val}]"
	    set packet(test,list2) "$packet(test,list2)   $val"
	}
    } elseif {$packet(content) == $pktfmt(C_TESTDSDV)} {
	#set packet(printall) 0
	set packet(dsdv,dest) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DV_DEST)]]]
	set packet(dsdv,nexthop) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DV_NEXTHOP)]]]
	set packet(dsdv,destseq) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DV_DESTSEQ)]]]
	set packet(dsdv,desthopcnt) [format "%d" 0x[lindex $bytes [expr $pktfmt(P_PAYLD) + $pktfmt(PD_DV_DESTHOPCNT)]]]
    } elseif {$packet(content) == $pktfmt(C_SETTINGS)} {
	#set packet(printall) 0
    } elseif {$packet(content) == $pktfmt(C_SETTINGS_SYNC)} {
	#set packet(printall) 0
	set packet(setsync,included) 1
	set packet(settings,setver)   [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_SETVER)]]
	set packet(settings,txres)    [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_TXRES)]]
	set packet(settings,enablemode) [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_ENABLE_MODE)]]
	set packet(settings,datamode) [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_DATA_MODE)]]
	set packet(settings,txrate)   [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_TXRATE)]]
	set packet(settings,hrate)    [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_HRATE)]]
    } elseif {$packet(content) == $pktfmt(C_SETTINGS_OLDISMC)} {
	#set packet(printall) 0
	set packet(setismc,included) 1
	set packet(setismc,setver)  [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_SETVER)]]
	set packet(setismc,txres)    [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_TXRES)]]
	set packet(setismc,txrate)   [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_TXRATE)]]
	set packet(setismc,qthold0)  [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_QTHOLD0)]]
	set packet(setismc,qthold1)  [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_QTHOLD1)]]
	set packet(setismc,qthold2)  [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_QTHOLD2)]]
	set packet(setismc,qtimeout) [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_QTIMEOUT)]]
	set packet(setismc,qpenalty) [format "%d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_QPENALTY)]]
	set packet(setismc,rupint)  [format "%3d" 0x[lindex $bytes $pktfmt(P_SETTINGS_OLDISMC_RUPINT)]]
    }

    return 1
}




