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

proc packet_print_init {} {
    global pktprt pktfmt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    set pktprt(init)            1
    set pktprt(hex)             0
    set pktprt(color)           0
    set pktprt(headers_only)    0

    set pktprt(color,reset)     0
    set pktprt(color,bright)    1
    set pktprt(color,dim)       2
    set pktprt(color,underline) 3
    set pktprt(color,blink)     4
    set pktprt(color,reverse)   7
    set pktprt(color,hidden)    8

    set pktprt(color,black)     0
    set pktprt(color,red)       1
    set pktprt(color,green)     2
    set pktprt(color,yellow)    3
    set pktprt(color,blue)      4
    set pktprt(color,magenta)   5
    set pktprt(color,cyan)      6
    set pktprt(color,white)     7

}

proc fmtaddr {addr} {
    global pktprt

    if {[info exists pktprt(init)] < 1} {
	packet_print_init
    }

    if {$pktprt(hex) > 0} {
	#make 2 character hex number the same width as 3 character decimal number
	return "0x[format "%02x" $addr]"
    } else {
	#return a 3 character decimal number
	return " [format "%3d"  $addr]"
    }
}

proc textcolor {attr fg bg} {
    global pktprt
    if {$pktprt(color) > 0} {
	puts -nonewline "\[$attr;[expr $fg + 30];[expr $bg + 40]m"
    }
}

proc print_rupdate_packet_section {packetName} {
    global pktfmt pktprt

    upvar 2 $packetName packet


    if {$packet(type) != $pktfmt(T_DSDV_RUPDATE_SOI)} {
	puts -nonewline "\[Dest:[fmtaddr $packet(dru_dest)] Seq:$packet(dru_seq) Cost:$packet(dru_hop) Sndr:[fmtaddr $packet(dru_sender)]\] "
    } else {
	puts -nonewline "\[Dest:[fmtaddr $packet(soiru_dest)] Seq:$packet(soiru_seq) ID1:$packet(soiru_id1) FC1:$packet(soiru_fc1) VC1:$packet(soiru_vc1) ID2:$packet(soiru_id2) FC2:$packet(soiru_fc2) VC2:$packet(soiru_vc2)\] "
    }

    if {$packet(type) != $pktfmt(T_DSDV_RUPDATE_HOPS)} {
	if {$pktprt(headers_only) == 0} {
	    set nbrstr "  NBRQUALITY: "
	    set numthr 3

	    for {set th 0} {$th <= $numthr} {incr th} {
		set th_val [expr $numthr - $th]
		set nbrstr [append nbrstr "\[ "]
		for {set i 0} {$i < $packet(nbr,th${th_val},cnt)} {incr i} {
		    set nbrstr [append nbrstr "[fmtaddr $packet(nbr,th${th_val},$i)] "]
		}
		set nbrstr [append nbrstr "\]"]
	    }


	    puts -nonewline "$nbrstr"

	    #puts "$packet(nbrlist)"
	}
    }
}


proc print_nbrstats_packet_section {packetName} {
    global pktfmt

    upvar 2 $packetName packet

    set nbrstr ""
    for {set i 0} {$i < $packet(nbrstats,cnt)} {incr i} {
	set nbrstr [append nbrstr "[fmtaddr $packet(nbrstats,$i,addr)]($packet(nbrstats,$i,stat)) "]
    }

    puts -nonewline "$nbrstr"

    #puts -nonewline  "\t\t -- $packet(nbrlist)"
}


proc print_hello_packet_section {packetName} {
    global pktfmt

    upvar 2 $packetName packet

    set nbr_and_relayliststr ""
    for {set i 0} {$i < $packet(nbrcnt)} {incr i} {
	set nbr_and_relayliststr [append nbr_and_relayliststr "[fmtaddr $packet(nbr,$i)] "]
    }

    puts -nonewline "\[A:[fmtaddr $packet(addr)] M:$packet(metric) R:$packet(relay)\] \[N($packet(nbrcnt)): $nbr_and_relayliststr\]"
}


proc print_relayorg2_packet_section {packetName} {
    global pktfmt

    upvar 2 $packetName packet

    set prnliststr ""
    for {set i 0} {$i < $packet(ro,prncnt)} {incr i} {
	set addr $packet(ro,prnlist,$i,addr)
	set mode $packet(ro,prnlist,$i,mode)
	set conn $packet(ro,prnlist,$i,conn)
	set seqn $packet(ro,prnlist,$i,seqn)
	set prnliststr [append prnliststr "[fmtaddr $addr]($mode $conn $seqn) "]
    }

    puts -nonewline "\[A:[fmtaddr $packet(addr)] S\#:$packet(ro,seq) M:$packet(ro,metric) S:[format "%02x" $packet(ro,state)]($packet(ro,statestr)) MyPR:[fmtaddr $packet(ro,mypr)]\] \[N($packet(ro,prncnt)): [format "%-80s" $prnliststr]\]"
}



proc format_traceroute_string {packetName} {
    global pktfmt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar $packetName packet

    if {$packet(content) == $pktfmt(C_TRACEROUTE) || $packet(content) == $pktfmt(C_VOTE_TRACEROUTE) || $packet(content) == $pktfmt(C_TRACEROUTE_SYNC)} {
	if {$packet(hopcount) <= $packet(maxhopcount)} {
	    set trrtstr [fmtaddr $packet(origsndr)]
	} else {
	    set trrtstr "  "
	}
	for {set i 0} {$i < $packet(hop,total)} {incr i} {
	    set trrtstr [append trrtstr " [fmtaddr $packet(hop,$i)]"]
	}
    } else {
	set trrtstr "<NO TRACEROUTE>"
    }

    return $trrtstr
}



proc print_flood_packet_section {packetName} {
    global pktfmt pktprt

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar 2 $packetName packet

    if {$pktfmt(nesc) == 1} {
	puts -nonewline "\[S:[fmtaddr $packet(mhopsndr)] D:[fmtaddr $packet(mhopdest)] A:$packet(mhopapp) L:$packet(mhoplen)\] "
	
	if {$packet(type) == $pktfmt(T_FLOOD)} {
	    puts -nonewline "\[S#:$packet(floodseq) T:$packet(floodttl)\] "
	} elseif {$packet(type) == $pktfmt(T_DSDV) || $packet(type) == $pktfmt(T_DSDV_SOI)} {
	    if {$packet(type) == $pktfmt(T_DSDV_SOI)} {
		puts -nonewline "\[SID: $packet(soi_sphereid)\] \[N:[fmtaddr $packet(soi_dsdvnext)] S#:$packet(soi_dsdvseq) T:$packet(soi_dsdvttl)\] "
	    } else {
		puts -nonewline "\[N:[fmtaddr $packet(dsdvnext)] S#:$packet(dsdvseq) T:$packet(dsdvttl)\] "
	    }
	}
	
	if {$packet(mhopapp) == $pktfmt(C_TRACEROUTE)} {
	    set trrtstr ""
	    for {set i 0} {$i < $packet(hop,total)} {incr i} {
		set trrtstr [append trrtstr " [fmtaddr $packet(hop,$i)]"]
	    }
	    puts -nonewline "<TRRT> "
	    puts -nonewline "\[H($packet(hop,total)) $trrtstr\] "
	} elseif {$packet(mhopapp) == $pktfmt(C_TRACEROUTE_SOI)} {
	    set trrtstr ""
	    set trrtstr_dbg ""
	    for {set i 0} {$i < $packet(hop,total)} {incr i} {
		set addr [fmtaddr $packet(hop,$i)]
		if {$packet(hop,$i,bit) > 0} {
		    set addr "${addr}*"
		} else {
		    set addr "${addr} "
		}
		set trrtstr [append trrtstr "$addr"]
		set trrtstr_dbg [append trrtstr_dbg " $packet(hop,$i)"]
	    }
	    puts -nonewline "<TRRT_SOI> "
	    puts -nonewline "($packet(hop,bits1) $packet(hop,bits2)) "
	    puts -nonewline "\[H([format "%2d" $packet(hop,total)]/[format "%2d" [expr $packet(hopcount) + 1]]) $trrtstr\] "
	    #puts -nonewline "\n($packet(hop,bits1) $packet(hop,bits2)) (($packet(hopcount)) $trrtstr_dbg)"
	} elseif {$packet(mhopapp) == $pktfmt(C_SETTINGS)} {
	    puts -nonewline "<SETTINGS> $packet(settings) "
	} else {
	    puts -nonewline "<UNKNOWNAPP:$packet(mhopapp)>  \[$packet(mhoppayload)\]"
	}

	puts -nonewline "<PBK> $packet(pgyback)"
#        if {$packet(type) == $pktfmt(T_DSDV) } {
#	    puts -nonewline " <ENERGY> $packet(energyval)"
#        }

	return
    }
    
    puts -nonewline "\["

    if {$packet(origsndr) == $packet(sndr)} {
	textcolor $pktprt(color,reset) $pktprt(color,green) $pktprt(color,black)
    }
    puts -nonewline "A:[fmtaddr $packet(origsndr)] S:$packet(origseq)"
    textcolor $pktprt(color,reset) $pktprt(color,white) $pktprt(color,black)

    if {$packet(printall) != 0} {
	puts -nonewline " D:[fmtaddr $packet(dest)] N:[fmtaddr $packet(nexthop)] T:$packet(ttl)\] "
    } else {
	puts -nonewline "\] "
    }

    if {$pktprt(headers_only) == 0} {
	if {$packet(content) == $pktfmt(C_OCCUPANCY_STATE)} {
	    puts -nonewline "<OCCS> "
	    puts -nonewline "\[$packet(name) $packet(state) "
	    if {$packet(extra,valid) > 0} {
		#puts -nonewline "|| $packet(extra,tempf) $packet(extra,voltage) $packet(extra,current) "
		#puts -nonewline "|| $packet(extra,tempraw1) $packet(extra,tempraw2) $packet(extra,voltage) $packet(extra,current) "
		puts -nonewline "|| $packet(extra,tempraw) $packet(extra,voltage) $packet(extra,current) "
	    }
	    puts -nonewline "\]"
	} elseif {$packet(content) == $pktfmt(C_DSDV_RUPDATE)} {
	    puts -nonewline "<DSDV_RUPDATE> $packet(nbrstr)"
	} elseif {$packet(content) == $pktfmt(C_TEMPERATURE)} {
	    puts -nonewline "<TEMP> "
	    puts -nonewline "\[$packet(name) "
	    if {$packet(extra,valid) > 0} {
		#puts -nonewline "|| $packet(extra,tempf) degrees F "
		puts -nonewline "|| $packet(extra,tempraw1) $packet(extra,tempraw2)  ==> $packet(extra,tempf) degrees F ==> [expr $packet(extra,tempraw1) - 22]"
		#puts -nonewline "|| $packet(extra,tempraw) "
	    }
	    puts -nonewline "\]"
	} elseif {$packet(content) == $pktfmt(C_VOTEDATA)} {
	    puts -nonewline "<VOTEDATA> "
	    puts -nonewline "\[count: $packet(votedata,numcat) --"
	    for {set i 0} {$i < $packet(votedata,numcat)} {incr i} {
		puts -nonewline " $packet(votedata,cat$i)"
	    }
	    puts -nonewline "\]"
	} elseif {$packet(content) == $pktfmt(C_NODENAME)} {
	    puts -nonewline "<NAME> "
	    puts -nonewline "\[$packet(name)\]"
	} elseif {$packet(content) == $pktfmt(C_NBRLIST)} {
	    puts -nonewline "<NBRL> "

	    set nbrliststr ""
	    for {set i 0} {$i < $packet(nbrcnt)} {incr i} {
		set nbrliststr [append nbrliststr "[fmtaddr $packet(nbr,$i)] "]
	    }

	    puts -nonewline "\[A:[fmtaddr $packet(origsndr)] T:$packet(nodetype)\] \[N($packet(nbrcnt)): $nbrliststr\]"
	} elseif {$packet(content) == $pktfmt(C_TRACEROUTE) || $packet(content) == $pktfmt(C_VOTE_TRACEROUTE) || $packet(content) == $pktfmt(C_TRACEROUTE_SYNC)} {
	    puts -nonewline "<TRRT> "
	    puts -nonewline [format "%-63s" "\[H($packet(hopcount)) [format_traceroute_string packet]\]"]
	    if {$packet(content) == $pktfmt(C_VOTE_TRACEROUTE)} {
		puts -nonewline " <VOTES> "
		puts -nonewline "\[$packet(settings,vote1) $packet(settings,vote2) $packet(settings,vote3) $packet(settings,vote4)\]"
	    }
	} elseif {$packet(content) == $pktfmt(C_SYNCSTATS)} {
	    puts -nonewline "<SYNCSTAT> "
	    puts -nonewline "\[HOPS:$packet(syncstats,hopcount) FCDROP:$packet(syncstats,fcachedropcnt) TXFAIL:$packet(syncstats,txfailcnt) SYNCNBR:$packet(syncstats,syncnbrcnt)\]"
	} elseif {$packet(content) == $pktfmt(C_SYNCSTATS2)} {
	    puts -nonewline "<SYNCSTAT2> "
	    puts -nonewline "\[TTIME:$packet(syncstats2,time_total) TXTIME:$packet(syncstats2,time_tx) RXTIME:$packet(syncstats2,time_rx) CPUTIME:$packet(syncstats2,time_cpu) SAVETIME:$packet(syncstats2,time_save)\]\n"
	    puts -nonewline "\t\t\[PTX:$packet(syncstats2,ptx) PRX:$packet(syncstats2,prx) PCPU:$packet(syncstats2,pcpu) PSAVE:$packet(syncstats2,psave)\]"
	} elseif {$packet(content) == $pktfmt(C_SYNCSTATS3)} {
	    puts -nonewline "<SYNCSTAT3> "
	    puts -nonewline "\[TXDATA:$packet(syncstats3,time_txdata) RXDATA:$packet(syncstats3,time_rxdata)\]\n"
	    puts -nonewline "\t\t\[PTXDATA:$packet(syncstats3,ptxdata) PRXDATA:$packet(syncstats3,prxdata)\]"
	    puts -nonewline "\t\t\[DTOTNBR:$packet(syncstats3,data_totnbrcnt) DACTNBR:$packet(syncstats3,data_actnbrcnt)\]"
	    puts -nonewline "\t\t\[TRELAY:$packet(syncstats3,time_relay) HRX:$packet(syncstats3,hello_rxcnt) HTX:$packet(syncstats3,hello_txcnt)\]"
	} elseif {$packet(content) == $pktfmt(C_TESTSOFTUART)} {
	    puts -nonewline "<SUART> "
	    puts -nonewline "\[$packet(test,count) $packet(test,list)\]"
	} elseif {$packet(content) == $pktfmt(C_TESTGATES)} {
	    puts -nonewline "<TGATES> "
	    puts -nonewline "\[$packet(test,count) $packet(test,list)\]"
	    puts -nonewline "\n                                      \{$packet(test,count) $packet(test,list2)\}"
	} elseif {$packet(content) == $pktfmt(C_TESTDSDV)} {
	    puts -nonewline "<TDSDV> "
	    puts -nonewline "\[DEST: [fmtaddr $packet(dsdv,dest)] NEXTHOP: [fmtaddr $packet(dsdv,nexthop)] DESTSEQ: $packet(dsdv,destseq) DESTHOPCNT: $packet(dsdv,desthopcnt)\]"
	} elseif {$packet(content) == $pktfmt(C_SETTINGS)} {
	    puts -nonewline "<SET> "
	    puts -nonewline "\[MODE: $packet(settings,mode) TXR: $packet(settings,txres) HRATE: $packet(settings,hrate) SRATE: $packet(settings,txrate)\]"
	} elseif {$packet(content) == $pktfmt(C_SETTINGS_SYNC)} {
	    puts -nonewline "<SET_SYNC> "
	    puts -nonewline "\[SETVER:$packet(settings,setver) DMODE: $packet(settings,datamode) EMODE: $packet(settings,enablemode) TXR: $packet(settings,txres) HRATE: $packet(settings,hrate) SRATE: $packet(settings,txrate)\]"
	} elseif {$packet(content) == $pktfmt(C_SETTINGS_OLDISMC)} {
	    puts -nonewline "  <SETTINGS_OLDISMC_COMMAND> "
	    puts -nonewline "\[SETVER:$packet(setismc,setver) TXR:$packet(setismc,txres) SRATE:$packet(setismc,txrate) QTh($packet(setismc,qthold0) $packet(setismc,qthold1) $packet(setismc,qthold2)) QTO:$packet(setismc,qtimeout) QP:$packet(setismc,qpenalty) RUI:$packet(setismc,rupint)\]"
	} else {
	    puts -nonewline "<Unknown Content: $packet(content)> "
	}

	# Print piggybacked data
	if {$packet(setval,included) > 0} {
	    puts -nonewline "  \n\t\t   "
	    puts -nonewline "  <SETFEEDBK> "
	    puts -nonewline "\[SETVER:$packet(setval,setver) PV:$packet(setval,progver)\] "

	    if {$packet(setval,std,included) > 0} {
		puts -nonewline "\[TXRES:$packet(setval,std,txres) SRATE:$packet(setval,std,txrate)\] "
	    }

	    if {$packet(setval,sync,included) > 0} {
		puts -nonewline "\[TTIME:$packet(setval,sync,ttime) RXC:$packet(setval,sync,rxcnt) TXC:$packet(setval,sync,txcnt) ATTR:$packet(setval,sync,nodeattr) PTX:$packet(setval,sync,ptx) PRX:$packet(setval,sync,prx) PSAVE:$packet(setval,sync,psave) PCPU:$packet(setval,sync,pcpu) METRIC:$packet(setval,sync,metric) TXRES:$packet(setval,sync,txres) \] "
	    }
	}
    }
}

proc print_packet {packetName} {
    global pktfmt
    global pktprt 

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init
    }

    upvar $packetName packet

    puts -nonewline "\[$packet(time)\] "

    if {$packet(synchpkt) > 0} {
	puts -nonewline "  <SYNCH> \[ "
	for {set i 0} {$i < 6} {incr i} {
	    puts -nonewline "$packet(synch,$i) "
	}
	puts -nonewline "\] "
	if {$packet(synch,type) == $pktfmt(SYNC_CNTRL_DSC) && $packet(synch,time) == 0} {
	    textcolor $pktprt(color,reset) $pktprt(color,red) $pktprt(color,black)
	    puts -nonewline "<DSCVRY>  "
	    textcolor $pktprt(color,reset) $pktprt(color,white) $pktprt(color,black)
	    #puts -nonewline "SNDR: [fmtaddr $packet(synch,sndr)] SEQ: $packet(synch,seq) DSEQ: $packet(synch,dscvry_seq) "
	    puts "SNDR: [fmtaddr $packet(synch,sndr)] SEQ: $packet(synch,seq) "
	    #if {$packet(synch,global_mode) == 4} {
		#puts "GMODE: <DSCVRY>"
	    #} elseif {$packet(synch,global_mode) == 6} {
		#puts "GMODE: <NORMAL>"
	    #} else {
		#puts "GMODE: $packet(synch,global_mode)"
	    #}
	} elseif {$packet(synch,type) == $pktfmt(SYNC_SOLICIT)} {
	    textcolor $pktprt(color,reset) $pktprt(color,blue) $pktprt(color,black)
	    puts -nonewline "<SOLICIT> "
	    textcolor $pktprt(color,reset) $pktprt(color,white) $pktprt(color,black)
	    puts "SNDR: [fmtaddr $packet(synch,sndr)] SEQ: $packet(synch,seq) "
	} else { 
	    textcolor $pktprt(color,reset) $pktprt(color,green) $pktprt(color,black)
	    puts -nonewline "<CNTRL>   "
	    textcolor $pktprt(color,reset) $pktprt(color,white) $pktprt(color,black)
	    puts "SNDR: [fmtaddr $packet(synch,sndr)] SEQ: $packet(synch,seq) TIME: $packet(synch,time) ==> ~$packet(synch,time_est)s"
	} 
	return 1
    }

    if {$packet(amtype) == 49} {
	#this is related to network programming
	# for now, just parse out nodeid info
	if {[info exists packet(prog,moteid)] > 0} {
	    puts "  <NETPROG INFO>   MoteId: [fmtaddr $packet(prog,moteid)]  NextProgId: $packet(prog,nextprogid)  NextProgLen: $packet(prog,nextprogsize)"
	} else {
	    puts "  <NetPROG INFO>"
	}
	return -1
    } elseif {[lsearch $pktfmt(amvalid) $packet(amtype)] < 0} {
	puts "dropping invalid AM packet: $packet(amtype) -- not in $pktfmt(amvalid)"
	return -1;
    }

    puts -nonewline "\[[fmtaddr $packet(sndr)] $packet(seq)\] "

    if {$pktfmt(nesc) == 1} {
	puts -nonewline "\[L:$packet(len)\] "
    }

    if {$packet(printall) != 0} {
	
	if {$packet(printlog) != 0} {
	    if {$packet(log,valid) > 0} {
		puts -nonewline "\[L [fmtaddr $packet(log,addr)] $packet(log,val) $packet(log,type) $packet(log,utime) $packet(log,ntime)\] "
	    } else {
		puts -nonewline "\[L                    \] "
	    }
	}
    } 

    if {$pktfmt(nesc) == 0 && $packet(type) == $pktfmt(T_HELLO)} {
	puts -nonewline "<H> "
	print_hello_packet_section $packetName
    } elseif {$pktfmt(nesc) == 0 && $packet(type) == $pktfmt(T_RELAYORG2)} {
	puts -nonewline "<RO> "
	print_relayorg2_packet_section $packetName
    } elseif {$packet(type) == $pktfmt(T_DSDV_RUPDATE_HOPS)} {
	puts -nonewline "<DSDV_RUPDATE_HOPS> "
	print_rupdate_packet_section $packetName
    } elseif {$packet(type) == $pktfmt(T_DSDV_RUPDATE_QUALITY)} {
	puts -nonewline "<DSDV_RUPDATE_QUALITY> "
	print_rupdate_packet_section $packetName
    } elseif {$packet(type) == $pktfmt(T_DSDV_RUPDATE_SOI)} {
	puts -nonewline "<DSDV_RUPDATE_SOI> "
	print_rupdate_packet_section $packetName
    } elseif {$pktfmt(nesc) == 0 && $packet(type) == $pktfmt(T_NBRSTATS)} {
	puts -nonewline "<NBRSTATS> "
	print_nbrstats_packet_section $packetName
    } elseif {$packet(type) == $pktfmt(T_FLOOD)} {
	puts -nonewline "<F> "
	print_flood_packet_section $packetName
    } elseif {$packet(type) == $pktfmt(T_DSDV) || $packet(type) == $pktfmt(T_DSDV_SOI)} {
	puts -nonewline "<D> "
	print_flood_packet_section $packetName
    } elseif {$packet(type) == $pktfmt(T_DSDV_RUPDATE_REQ)} {
	puts -nonewline "<DSDV_RUPDATE_REQ> "
    } elseif {$packet(type) == $pktfmt(T_TINYDB_QUERY)} {
        puts -nonewline "<TinyDB Query Message>"
    } elseif {$packet(type) == $pktfmt(T_TINYDB_COMMAND)} {
        puts -nonewline "<TinyDB Command Message>"
    } elseif {$packet(type) == $pktfmt(T_TINYDB_QUERY_REQ)} {
        puts -nonewline "<TinyDB Query Request Message>"
    } elseif {$packet(type) == $pktfmt(T_TINYDB_EVENT)} {
        puts -nonewline "<TinyDB Event Message>"
    } elseif {$packet(type) == $pktfmt(T_TINYDB_STATUS)} {
        puts -nonewline "<TinyDB Status Message>"
    } elseif {$packet(type) == $pktfmt(T_TINYDB_DATA)} {
        puts -nonewline "<TinyDB Data Message>"
    } else {
	puts -nonewline "<Unknown Type: $packet(type)>"
    }

    puts ""
}






