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
# Authors:      Steve Conner, Mark Yarvis
#
#

lappend auto_path .

proc uartserver_connector_socket_handler {fd} {
    global UartConnVar

    if {[gets $fd rcvbuf] >= 0} {
	set packet [string trim $rcvbuf]
#	puts "RECEIVED: \"$packet\""
	
	$UartConnVar(packet_handler) $packet
    } else {
	puts stderr "Error reading from socket..."

	if {[catch {close $UartConnVar(socket,old)} fid]} {
	    puts stderr "Error closing old socket: $UartConnVar(socket,old) -- $fid"
	} else {
	    set UartConnVar(socket,old) -1
	}

	after 100 uartserver_connector_socket_connect 1
    }
}

proc uartserver_connector_socket_connect {{error 0}} {
    global UartConnVar

    if {$error > 0} {
	puts -nonewline stderr "Error: Attempting reconnect to uartserver at "
    } else {
	puts -nonewline stderr "Connecting to uartserver at "
    }
    puts stderr "$UartConnVar(server,addr):$UartConnVar(server,port)... "

    if {[catch {set UartConnVar(socket,current) [socket $UartConnVar(server,addr) $UartConnVar(server,port)]} fid]} {
	puts stderr "Failed to connect: $fid"
	after 1000 uartserver_connector_socket_connect 1
    } else {
	puts stderr "Connected... socket: $UartConnVar(socket,current)\n"
	if {$UartConnVar(socket,old) != -1} {
	    if {[catch {close $UartConnVar(socket,old)} fid]} {
		puts stderr "Error closing old socket: $UartConnVar(socket,old) -- $fid"
	    }
	}
	set UartConnVar(socket,old) $UartConnVar(socket,current)
	fileevent $UartConnVar(socket,current) readable "uartserver_connector_socket_handler $UartConnVar(socket,current)"
    }
}

proc uartserver_connector_send {packet} {
    global UartConnVar
    puts $UartConnVar(socket,current) $packet
    flush $UartConnVar(socket,current)
    puts stderr "Sending: $packet"
    flush stderr
}

proc uartserver_connector_init {server packet_handler} {
    global UartConnVar
    set UartConnVar(socket,current) -1
    set UartConnVar(socket,old)     -1
    
    set UartConnVar(packet_handler) $packet_handler
    
    set srvlist [split $server ":"]
    if {[llength $srvlist] == 2} {
	set UartConnVar(server,addr) [lindex $srvlist 0]
	set UartConnVar(server,port) [lindex $srvlist 1]
    } else {
	set UartConnVar(server,addr) $server
	set UartConnVar(server,port) 9001
    }

    uartserver_connector_socket_connect
}

proc uartserver_connector_reconnect {server} {
    global UartConnVar

    set srvlist [split $server ":"]
    if {[llength $srvlist] == 2} {
	set UartConnVar(server,addr) [lindex $srvlist 0]
	set UartConnVar(server,port) [lindex $srvlist 1]
    } else {
	set UartConnVar(server,addr) $server
	set UartConnVar(server,port) 9001
    }

    if {[catch {close $UartConnVar(socket,old)} fid]} {
        puts stderr "Error closing old socket: $UartConnVar(socket,old) -- $fid"
    } else {
        set UartConnVar(socket,old) -1
    }

    after 100 uartserver_connector_socket_connect 1
}
