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


proc packet_handler {packet} {
    parse_packet $packet pktvar
    erase_time
    print_packet pktvar
    unset pktvar
    update_time 0
    flush stdout
}

proc print_usage {} {
    global argv0
    puts "Usage: $argv0 \[-hex\] \[-color\] \[-headers\] \[-live_time\] \[-r server\]"
    puts "\t-hex:     print addresses in hex"
    puts "\t-headers: print packets headers only, no payload data"
    exit
}

proc read_stdin {} {
    global pktprt

    puts "read_stdin called... [fblocked stdin]"

    set char [read stdin 1]

    puts "fblocked stdin: [fblocked stdin]"

    if {$char == "h"} {
	puts "Mode: hex"
	set pktprt(hex) 1
    } elseif {$char == "d"} {
	puts "Mode: decimal"
	set pktprt(hex) 0
    }
}

proc erase_time {} {
    global live_time
    if {$live_time > 0 } {
	puts -nonewline "\b\b\b\b\b\b\b\b\b\b"
    }
}

proc update_time {{erase 1}} {
    global pktprt live_time

    if {$live_time > 0 } {
	after 1000 update_time
	set time [clock format [clock seconds] -format "%H:%M:%S"]
	if {$erase > 0} {
	    erase_time
	}
	textcolor $pktprt(color,dim) $pktprt(color,cyan) $pktprt(color,black)
	puts -nonewline "\[$time\]"
	textcolor $pktprt(color,reset) $pktprt(color,white) $pktprt(color,black)
	flush stdout
    }
}

set server "127.0.0.1"
set next_is_ip 0

global live_time
set live_time 0
#set use_nesc 0
set use_nesc 1

foreach arg $argv {
    global pktprt

    if {$arg == "-r"} {
	set next_is_ip 1
    } elseif {$next_is_ip == 1} {
	set server $arg
	set next_is_ip 0
    } elseif {$arg == "-hex"} {
	set pktprt(hex) 1
#    } elseif {$arg == "-nesc"} {
#	set use_nesc 1
    } elseif {$arg == "-color"} {
	set pktprt(color) 1
    } elseif {$arg == "-headers"} {
	set pktprt(headers_only) 1
    } elseif {$arg == "-livetime"} {
	set live_time 1
    } else {
	print_usage
    }
}

if {$next_is_ip != 0} {
    print_usage
}



packet_format_init $use_nesc
packet_print_init




uartserver_connector_init $server packet_handler

fconfigure stdin -blocking 0 -buffering none
#Disable read_stdin since causes read block under cygwin,
#  despite the nonblocking configuration...  Is this a Tcl or cygwin bug?
#fileevent stdin r "read_stdin"


if {$live_time > 0} {
    after 200 update_time
}

vwait enter-mainloop









