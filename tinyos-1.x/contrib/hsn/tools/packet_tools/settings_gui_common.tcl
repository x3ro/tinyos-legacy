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

#Example usage:  (see settings_gui.tcl)
#
#lappend auto_path .
#packet_format_init
#global pktfmt
#
#settings_gui_common_init $pktfmt(C_SETTINGS)
#
#set setgrp [settings_gui_common_create_group 1  "Feedback List"]
#settings_gui_common_add_entry            $setgrp "FB ID:"             1 255 1
#settings_gui_common_add_varlen_checklist $setgrp "ID List:"           [list {1 0} {2 0} {4 0}]
#
#set setgrp [settings_gui_common_create_group 2  "Feedback ID"]
#settings_gui_common_add_entry            $setgrp "FB ID:"             1 255 1
#
#set setgrp [settings_gui_common_create_group 4  "Setting Version"]
#settings_gui_common_add_setver $setgrp
#
#settings_gui_common_start
#
#
#
# End Example



proc settings_gui_common_print_usage {} {
    global argv0
    puts "Usage: $argv0 \[-r server\]"
    exit
}


proc handle_packet {packet} {

}


proc settings_gui_common_init {{type ""} {local_group ""} {minimal_gui ""} {server_init ""}} {
    global SettingsVar
    global argv
    global pktfmt
    
    if {$type == ""} {
	set SettingsVar(type) $pktfmt(C_SETTINGS)
    } else {
	set SettingsVar(type) $type
    }
    
    if {$local_group == ""} {
	set SettingsVar(localgroup) "7d"
    } else {
	set SettingsVar(localgroup) $local_group
    }

    if {$minimal_gui == ""} {
	set SettingsVar(minimalgui) 0
    } else {
	set SettingsVar(minimalgui) 1
    }

    set SettingsVar(settings,cnt) 0
    set SettingsVar(settings,sendcnt) 0

    set next_is_ip 0

    set server_arg ""

    foreach arg $argv {
	if {$arg == "-r"} {
	    set next_is_ip 1
	} elseif {$next_is_ip == 1} {
	    set server_arg $arg
	    set next_is_ip 0
	} else {
	    settings_gui_common_print_usage
	}
    }

    if {$next_is_ip != 0} {
	settings_gui_common_print_usage
    }

    if {$server_init != ""} {
	puts "SettingsGUI: Using init uartserver: $server_init"
	set SettingsVar(server) $server_init
    } elseif {$server_arg != ""} {
	puts "SettingsGUI: Using arg uartserver: $server_arg"
	set SettingsVar(server) $server_arg
    } else {
	puts "SettingsGUI: Using default uartserver: 127.0.0.1"
	set SettingsVar(server) "127.0.0.1"
    }

    uartserver_connector_init $SettingsVar(server) handle_packet

    after 1000 auto_send_settings
}

proc settings_gui_common_create_group {id name} {
    global SettingsVar

    set i $SettingsVar(settings,cnt)

    set SettingsVar(settings,$i,id)   $id
    set SettingsVar(settings,$i,name) $name
    set SettingsVar(settings,$i,cnt)  0
    set SettingsVar(settings,$i,send)  0

    incr SettingsVar(settings,cnt)

    return $i
}

proc settings_gui_common_add_rangeval {setgrp name min max defaultval} {
    global SettingsVar

    set j $SettingsVar(settings,$setgrp,cnt)

    set SettingsVar(settings,$setgrp,$j,type) rangeval
    set SettingsVar(settings,$setgrp,$j,name) $name
    set SettingsVar(settings,$setgrp,$j,min)  $min
    set SettingsVar(settings,$setgrp,$j,max)  $max
    set SettingsVar(settings,$setgrp,$j,defaultval) $defaultval
    set SettingsVar(settings,$setgrp,$j,val)  $defaultval

    incr SettingsVar(settings,$setgrp,cnt)
}

proc settings_gui_common_draw_rangeval {setgrp item frame} {
    global SettingsVar
    label ${frame}.${item}_lbl -textvariable SettingsVar(settings,$setgrp,$item,name)
    entry ${frame}.${item}_val -textvariable SettingsVar(settings,$setgrp,$item,val) -width 5
    pack ${frame}.${item}_lbl ${frame}.${item}_val -side left
}

proc settings_gui_common_pack_rangeval {setgrp item} {
    global SettingsVar
    if {$SettingsVar(settings,$setgrp,$item,val) > 
            $SettingsVar(settings,$setgrp,$item,max)} {
       return $SettingsVar(settings,$setgrp,$item,max);
    } elseif {$SettingsVar(settings,$setgrp,$item,val) < 
            $SettingsVar(settings,$setgrp,$item,min)} {
       return $SettingsVar(settings,$setgrp,$item,min);
    } else {
       return $SettingsVar(settings,$setgrp,$item,val)
    }
}

proc settings_gui_common_reset_rangeval {setgrp item} {
    global SettingsVar
    set SettingsVar(settings,$setgrp,$item,val) $SettingsVar(settings,$setgrp,$item,defaultval)
}

proc settings_gui_common_add_incrval {setgrp name min max defaultval} {
    global SettingsVar

    set j $SettingsVar(settings,$setgrp,cnt)

    set SettingsVar(settings,$setgrp,$j,type) incrval
    set SettingsVar(settings,$setgrp,$j,name) $name
    set SettingsVar(settings,$setgrp,$j,min)  $min
    set SettingsVar(settings,$setgrp,$j,max)  $max
    set SettingsVar(settings,$setgrp,$j,defaultval) $defaultval
    set SettingsVar(settings,$setgrp,$j,val)  $defaultval

    incr SettingsVar(settings,$setgrp,cnt)
}

proc settings_gui_common_draw_incrval {setgrp item frame} {
    global SettingsVar
    label ${frame}.${item}_lbl -textvariable SettingsVar(settings,$setgrp,$item,name)
    entry ${frame}.${item}_val -textvariable SettingsVar(settings,$setgrp,$item,val) -width 5
    button ${frame}.${item}_incrbtn -text "Incr" -command "settings_gui_common_increment_incrval SettingsVar(settings,$setgrp,$item,val)"
    pack ${frame}.${item}_lbl ${frame}.${item}_val ${frame}.${item}_incrbtn -side left
}

proc settings_gui_common_increment_incrval {varname} {
    upvar #0 $varname var

    if {[catch {
	incr var
	if {$var > 255} {
	    set var 1
	} elseif {$var < 1} {
	    set var 1
	}
    } err]} {
	set var 1
    }
}

proc settings_gui_common_pack_incrval {setgrp item} {
    global SettingsVar
    if {$SettingsVar(settings,$setgrp,$item,val) > 
            $SettingsVar(settings,$setgrp,$item,max)} {
       return $SettingsVar(settings,$setgrp,$item,max);
    } elseif {$SettingsVar(settings,$setgrp,$item,val) < 
            $SettingsVar(settings,$setgrp,$item,min)} {
       return $SettingsVar(settings,$setgrp,$item,min);
    } else {
       return $SettingsVar(settings,$setgrp,$item,val)
    }
}

proc settings_gui_common_reset_incrval {setgrp item} {
    global SettingsVar
    set SettingsVar(settings,$setgrp,$item,val) $SettingsVar(settings,$setgrp,$item,defaultval)
}

proc settings_gui_common_add_checkbox {setgrp name defaultval} {
    global SettingsVar

    set j $SettingsVar(settings,$setgrp,cnt)

    set SettingsVar(settings,$setgrp,$j,type) checkbox
    set SettingsVar(settings,$setgrp,$j,name) $name
    set SettingsVar(settings,$setgrp,$j,defaultval) $defaultval
    set SettingsVar(settings,$setgrp,$j,val)  $defaultval

    incr SettingsVar(settings,$setgrp,cnt)
}

proc settings_gui_common_draw_checkbox {setgrp item frame} {
    global SettingsVar
    checkbutton ${frame}.${item}_cbox -variable SettingsVar(settings,$setgrp,$item,val) -text $SettingsVar(settings,$setgrp,$item,name)
    pack ${frame}.${item}_cbox -side left
}

proc settings_gui_common_pack_checkbox {setgrp item} {
    global SettingsVar
    return $SettingsVar(settings,$setgrp,$item,val)
}

proc settings_gui_common_reset_checkbox {setgrp item} {
    global SettingsVar
    set SettingsVar(settings,$setgrp,$item,val) $SettingsVar(settings,$setgrp,$item,defaultval)
}

proc settings_gui_common_add_addrlist {setgrp name thelist {width 40}} {
    global SettingsVar

    set j $SettingsVar(settings,$setgrp,cnt)

    set SettingsVar(settings,$setgrp,$j,type) addrlist
    set SettingsVar(settings,$setgrp,$j,name) $name
    set SettingsVar(settings,$setgrp,$j,defaultval) $thelist
    set SettingsVar(settings,$setgrp,$j,entryval)  $thelist
    set SettingsVar(settings,$setgrp,$j,entrywidth)  $width

    incr SettingsVar(settings,$setgrp,cnt)
}

proc settings_gui_common_draw_addrlist {setgrp item frame} {
    global SettingsVar
    set listf [frame ${frame}.${item}_listf]
    set listf_1 [frame ${listf}.f1]
    label ${listf_1}_lbl -textvariable SettingsVar(settings,$setgrp,$item,name)
    entry ${listf_1}_val -textvariable SettingsVar(settings,$setgrp,$item,entryval) -width $SettingsVar(settings,$setgrp,$item,entrywidth)
    label ${listf}_parseinfo -textvariable SettingsVar(settings,$setgrp,$item,parseinfo)
    bind ${listf_1}_val <KeyRelease> "settings_gui_common_parse_addrlist $setgrp $item"
    bind ${listf_1}_val <ButtonRelease> "settings_gui_common_parse_addrlist $setgrp $item"
    pack ${listf_1}_lbl ${listf_1}_val -side left
    pack ${listf_1} -anchor w -side top
    pack ${listf}_parseinfo -anchor w -side bottom
    pack $listf -side left

    settings_gui_common_parse_addrlist $setgrp $item
}

proc settings_gui_common_parse_addrlist {setgrp item} {
    global SettingsVar

    #get rid of extra spaces, including leading spaces
    regsub -all { +} [string trimleft $SettingsVar(settings,$setgrp,$item,entryval)] { } SettingsVar(settings,$setgrp,$item,entryval)

    # split after removing any trailing spaces
    set thelist [split [string trim $SettingsVar(settings,$setgrp,$item,entryval)]]
    #puts "Converting list -- $SettingsVar(settings,$setgrp,$item,entryval) -- $thelist"

    set SettingsVar(settings,$setgrp,$item,val) ""
    set discard ""
    foreach listitem $thelist {
	set discardit 0
	if {[catch {
	    if {$listitem > 255} {
		set discardit 1
	    } elseif {$listitem < 0} {
		set discardit 1
	    }
	} err]} {
	    set discardit 1
	}
	
	if {$discardit > 0} {
	    lappend discard $listitem
	} else {
	    lappend SettingsVar(settings,$setgrp,$item,val) $listitem
	}
    }

    set SettingsVar(settings,$setgrp,$item,parseinfo) "valid: $SettingsVar(settings,$setgrp,$item,val)   discard: $discard"

    settings_gui_common_verify_payload SettingsVar(settings,$setgrp,send)
}


proc settings_gui_common_pack_addrlist {setgrp item} {
    global SettingsVar

    set vallist $SettingsVar(settings,$setgrp,$item,val)
    set l [llength $vallist]
    if {$l > 0} {
	set vallist [concat $l $vallist]
    } else {
	set vallist 0
    }

    #puts "vallist: $vallist"
    return $vallist
}

proc settings_gui_common_reset_addrlist {setgrp item} {
    global SettingsVar
    set SettingsVar(settings,$setgrp,$item,val) $SettingsVar(settings,$setgrp,$item,defaultval)
    settings_gui_common_parse_addrlist $setgrp $item
}

proc settings_gui_common_add_optionlist {setgrp name namevallist defaultval} {
    global SettingsVar

    set j $SettingsVar(settings,$setgrp,cnt)
    
    set SettingsVar(settings,$setgrp,$j,type) optionlist
    set SettingsVar(settings,$setgrp,$j,name) $name
    set SettingsVar(settings,$setgrp,$j,defaultval) $defaultval
    set SettingsVar(settings,$setgrp,$j,val) $defaultval

    set valcnt [llength $namevallist]
    set SettingsVar(settings,$setgrp,$j,cnt) $valcnt
    for {set k 0} {$k < $valcnt} {incr k} {
	set option [lindex $namevallist $k]
	set SettingsVar(settings,$setgrp,$j,$k,name) [lindex $option 0]
	set SettingsVar(settings,$setgrp,$j,$k,val)  [lindex $option 1]
    }

    settings_gui_common_reset_optionlist $setgrp $j

    incr SettingsVar(settings,$setgrp,cnt)
}

proc settings_gui_common_draw_optionlist {setgrp item frame} {
    global SettingsVar
    for {set k 0} {$k < $SettingsVar(settings,$setgrp,$item,cnt)} {incr k} {
	checkbutton ${frame}.${item}_${k}_cbox -variable SettingsVar(settings,$setgrp,$item,$k,curval) \
		-text $SettingsVar(settings,$setgrp,$item,$k,name)
	pack ${frame}.${item}_${k}_cbox -side left
    }
}

proc settings_gui_common_pack_optionlist {setgrp item} {
    global SettingsVar
    set SettingsVar(settings,$setgrp,$item,val) 0
    for {set k 0} {$k < $SettingsVar(settings,$setgrp,$item,cnt)} {incr k} {
	if {$SettingsVar(settings,$setgrp,$item,$k,curval) > 0} {
	    incr SettingsVar(settings,$setgrp,$item,val) $SettingsVar(settings,$setgrp,$item,$k,val)
	}
    }

    return $SettingsVar(settings,$setgrp,$item,val)
}

proc settings_gui_common_reset_optionlist {setgrp item} {
    global SettingsVar

    if {$SettingsVar(settings,$setgrp,$item,type) == "optionlist"} {
	for {set k 0} {$k < $SettingsVar(settings,$setgrp,$item,cnt)} {incr k} {
	    #puts -nonewline "setting default from $SettingsVar(settings,$i,option,$j,val) $SettingsVar(settings,$i,defaultval) [expr $SettingsVar(settings,$i,option,$j,val) & $SettingsVar(settings,$i,defaultval)] ==> "
	    if {[expr $SettingsVar(settings,$setgrp,$item,$k,val) & $SettingsVar(settings,$setgrp,$item,defaultval)] > 0} {
		set SettingsVar(settings,$setgrp,$item,$k,curval) 1
	    } else {
		set SettingsVar(settings,$setgrp,$item,$k,curval) 0
	    }
	    #puts "$SettingsVar(settings,$i,option,$j,curval)"
	}
    }
}

proc settings_gui_common_add_vchecklist {setgrp name thelist} {
    global SettingsVar

    set j $SettingsVar(settings,$setgrp,cnt)

    set SettingsVar(settings,$setgrp,$j,type) vchecklist
    set SettingsVar(settings,$setgrp,$j,name) $name

    set valcnt [llength $thelist]
    set SettingsVar(settings,$setgrp,$j,cnt) $valcnt
    for {set k 0} {$k < $valcnt} {incr k} {
	set item [lindex $thelist $k]
	set SettingsVar(settings,$setgrp,$j,$k,name) [lindex $item 0]
	set SettingsVar(settings,$setgrp,$j,$k,defaultval) [lindex $item 1]
	set SettingsVar(settings,$setgrp,$j,$k,val) [lindex $item 1]
    }

    incr SettingsVar(settings,$setgrp,cnt)
}

proc settings_gui_common_draw_vchecklist {setgrp item frame} {
    global SettingsVar
    for {set k 0} {$k < $SettingsVar(settings,$setgrp,$item,cnt)} {incr k} {
	checkbutton ${frame}.${item}_${k}_cbox -variable SettingsVar(settings,$setgrp,$item,$k,val) \
		-text $SettingsVar(settings,$setgrp,$item,$k,name)  -command "settings_gui_common_verify_payload SettingsVar(settings,$setgrp,$item,$k,val)"
	pack ${frame}.${item}_${k}_cbox -side left
    }
}

proc settings_gui_common_pack_vchecklist {setgrp item} {
    global SettingsVar
    set vallist ""
    for {set k 0} {$k < $SettingsVar(settings,$setgrp,$item,cnt)} {incr k} {
	if {$SettingsVar(settings,$setgrp,$item,$k,val) > 0} {
	    lappend vallist $SettingsVar(settings,$setgrp,$item,$k,name)
	}
    }
    set l [llength $vallist]
    if {$l > 0} {
	set vallist [concat $l $vallist]
    } else {
	set vallist 0
    }

    #puts "vallist: $vallist"
    return $vallist
}

proc settings_gui_common_reset_vchecklist {setgrp item} {
    global SettingsVar
    for {set k 0} {$k < $SettingsVar(settings,$setgrp,$item,cnt)} {incr k} {
	set SettingsVar(settings,$setgrp,$item,$k,val) $SettingsVar(settings,$setgrp,$item,$k,defaultval)
    }
}

proc settings_gui_common_add_setver {setgrp} {
    global SettingsVar

    set j $SettingsVar(settings,$setgrp,cnt)

    set SettingsVar(settings,$setgrp,$j,type) "setver"
    set SettingsVar(setver,autoincr,enabled) "1"
    set SettingsVar(setver) "1"

    incr SettingsVar(settings,$setgrp,cnt)
}

proc settings_gui_common_draw_setver {setgrp item frame} {
    global SettingsVar
    entry ${frame}.${item}_val -textvariable SettingsVar(setver) -width 5
    button ${frame}.${item}_incrbtn -text "Incr" -command "settings_gui_common_increment_incrval SettingsVar(setver)"
    #checkbutton ${frame}.${item}_autoincrbtn -text "Auto Increment" -variable SettingsVar(setver,autoincr,enabled) -command {
#	global SettingsVar
#	if {$SettingsVar(setver,autoincr,enabled) > 0 && $SettingsVar(foundchange) > 0} {
#	    settings_gui_common_increment_setver
#	}
#    }
    #pack ${frame}.${item}_val ${frame}.${item}_incrbtn ${frame}.${item}_autoincrbtn -side left
    pack ${frame}.${item}_val ${frame}.${item}_incrbtn -side left
}


proc settings_gui_common_pack_setver {} {
    global SettingsVar
    if {$SettingsVar(setver) > 255} {
       return 255
    } elseif {$SettingsVar(setver) < 0} {
       return 0
    } else {
       return $SettingsVar(setver)
    }
}

proc settings_gui_common_set_setver {value} {
    global SettingsVar
    set SettingsVar(setver) $value
}

proc settings_gui_common_set_dest {value} {
    global SettingsVar
    set SettingsVar(dest) $value
}

proc settings_gui_common_reset_defaults {{initlastsentvals 0}} {
    global SettingsVar

    for {set i 0} {$i < $SettingsVar(settings,cnt)} {incr i} {
	set SettingsVar(settings,$i,send) 0
	for {set j 0} {$j < $SettingsVar(settings,$i,cnt)} {incr j} {
	    if {$SettingsVar(settings,$i,$j,type) == "rangeval"} {
		settings_gui_common_reset_rangeval $i $j
	    } elseif {$SettingsVar(settings,$i,$j,type) == "incrval"} {
		settings_gui_common_reset_incrval $i $j
	    } elseif {$SettingsVar(settings,$i,$j,type) == "checkbox"} {
		settings_gui_common_reset_checkbox $i $j
	    } elseif {$SettingsVar(settings,$i,$j,type) == "addrlist"} {
		settings_gui_common_reset_addrlist $i $j
	    } elseif {$SettingsVar(settings,$i,$j,type) == "optionlist"} {
		settings_gui_common_reset_optionlist $i $j
	    } elseif {$SettingsVar(settings,$i,$j,type) == "vchecklist"} {
		settings_gui_common_reset_vchecklist $i $j
	    }
	}
    }

    set SettingsVar(msgsize)  29
    set SettingsVar(ttl)  12
    set SettingsVar(dest) 255

    if {$initlastsentvals > 0} {
	set SettingsVar(firstsenddone) 0
	set SettingsVar(foundchange) 0
	set SettingsVar(ttl,lastsend)  0
	set SettingsVar(dest,lastsend) 0
    }

    set SettingsVar(autosend,interval) 1000
    set SettingsVar(autosend,interval,lastsendval) 1000
    #set SettingsVar(autosend,mult)     1000
    set SettingsVar(autosend,mult)     1
    set SettingsVar(autosend,enabled)  0

    settings_gui_common_calc_payload
}

proc settings_gui_common_verify_payload {changedvarname} {
    global SettingsVar
    upvar #0 $changedvarname changedvar

    settings_gui_common_calc_payload

    if {$changedvar > 0 && $SettingsVar(payload,size) > 21} {
	set changedvar 0
	settings_gui_common_calc_payload
    }
}

proc settings_gui_common_calc_payload {} {
    global SettingsVar
    #puts "calc payload length:"
    set length 0
    set packlist ""
    for {set i 0} {$i < $SettingsVar(settings,cnt)} {incr i} {
	if {$SettingsVar(settings,$i,send) > 0} {
	    #puts "adding settings id $SettingsVar(settings,$i,id)"
	    lappend packlist $SettingsVar(settings,$i,id)
	    for {set j 0} {$j < $SettingsVar(settings,$i,cnt)} {incr j} {
		if {$SettingsVar(settings,$i,$j,type) == "rangeval"} {
		    set itemlist [settings_gui_common_pack_rangeval $i $j]
		} elseif {$SettingsVar(settings,$i,$j,type) == "incrval"} {
		    set itemlist [settings_gui_common_pack_incrval $i $j]
		} elseif {$SettingsVar(settings,$i,$j,type) == "checkbox"} {
		    set itemlist [settings_gui_common_pack_checkbox $i $j]
		} elseif {$SettingsVar(settings,$i,$j,type) == "addrlist"} {
		    set itemlist [settings_gui_common_pack_addrlist $i $j]
		} elseif {$SettingsVar(settings,$i,$j,type) == "optionlist"} {
		    set itemlist [settings_gui_common_pack_optionlist $i $j]
		} elseif {$SettingsVar(settings,$i,$j,type) == "vchecklist"} {
		    set itemlist [settings_gui_common_pack_vchecklist $i $j]
		} elseif {$SettingsVar(settings,$i,$j,type) == "setver"} {
		    set itemlist [settings_gui_common_pack_setver]
		} else {
		    puts "Error: unknown type: $SettingsVar(settings,$i,$j,type)"
		    continue
		}
		#puts "\t\t...j=$j -- [llength $itemlist]"
		set packlist [concat $packlist $itemlist]
	    }
	    
	}
    }
    puts "Total Length: [llength $packlist]  ==> $packlist"
    set SettingsVar(payload,size) [llength $packlist]
    set SettingsVar(payload,list) $packlist
}


proc settings_gui_common_start {} {
    global SettingsVar

    frame .controlframe

    label .controlframe.datasetlbl -text "Control Settings:" -fg blue
    grid .controlframe.datasetlbl -row 9 -column 0 -columnspan 3 -sticky nw
    grid rowconfigure .controlframe 9 -minsize 20

    for {set i 0} {$i < $SettingsVar(settings,cnt)} {incr i} {
	checkbutton .controlframe.${i}_check -text "" -variable SettingsVar(settings,$i,send) -command "settings_gui_common_verify_payload SettingsVar(settings,$i,send)"

	label .controlframe.${i}_label -text "[format "%2d" $SettingsVar(settings,$i,id)] $SettingsVar(settings,$i,name):"

	grid .controlframe.${i}_check -row [expr $i + 10] -column 0
	grid .controlframe.${i}_label -row [expr $i + 10] -column 1 -sticky w

	frame .controlframe.${i}_settings
	grid .controlframe.${i}_settings -row [expr $i + 10] -column 2 -sticky w
	set f .controlframe.${i}_settings

	#set item 0
	for {set j 0} {$j < $SettingsVar(settings,$i,cnt)} {incr j} {
	    if {$SettingsVar(settings,$i,$j,type) == "rangeval"} {
		settings_gui_common_draw_rangeval $i $j $f
	    } elseif {$SettingsVar(settings,$i,$j,type) == "incrval"} {
		settings_gui_common_draw_incrval $i $j $f
	    } elseif {$SettingsVar(settings,$i,$j,type) == "checkbox"} {
		settings_gui_common_draw_checkbox $i $j $f
	    } elseif {$SettingsVar(settings,$i,$j,type) == "addrlist"} {
		settings_gui_common_draw_addrlist $i $j $f
	    } elseif {$SettingsVar(settings,$i,$j,type) == "optionlist"} {
		settings_gui_common_draw_optionlist $i $j $f
	    } elseif {$SettingsVar(settings,$i,$j,type) == "vchecklist"} {
		settings_gui_common_draw_vchecklist $i $j $f
	    } elseif {$SettingsVar(settings,$i,$j,type) == "setver"} {
		settings_gui_common_draw_setver $i $j $f
	    }
	}
    }
    


#-----

    if {$SettingsVar(minimalgui) == 0} {

	frame .controlframe.separator1 -relief raised -height 6 -bd 3
	grid .controlframe.separator1 -row 28 -column 0 -columnspan 4 -sticky ew
	grid rowconfigure .controlframe 28 -minsize 20

	label .controlframe.pktsetlbl -text "Packet Settings:" -fg blue
	grid .controlframe.pktsetlbl -row 29 -column 0 -columnspan 3 -sticky nw
	grid rowconfigure .controlframe 29 -minsize 20

	label .controlframe.msgsizelabel -text "Message Size:"
	entry .controlframe.msgsize      -textvariable SettingsVar(msgsize)

	label .controlframe.plsizelabel -text "Payload Size:"
	label .controlframe.plsize      -textvariable SettingsVar(payload,size)

	label .controlframe.ttllabel -text "Flood TTL:"
	entry .controlframe.ttl -textvariable SettingsVar(ttl)

	label .controlframe.lgrplabel -text "Local Group (hex):"
	entry .controlframe.lgrp -textvariable SettingsVar(localgroup)

	label .controlframe.destlabel -text "Destination Addr:"
	entry .controlframe.dest -textvariable SettingsVar(dest)
	grid .controlframe.msgsizelabel -row 30 -column 1 -sticky w
	grid .controlframe.msgsize      -row 30 -column 2 -sticky w

	grid .controlframe.plsizelabel -row 31 -column 1 -sticky w
	grid .controlframe.plsize      -row 31 -column 2 -sticky w

	grid .controlframe.ttllabel -row 32 -column 1 -sticky w
	grid .controlframe.ttl      -row 32 -column 2 -sticky w

	grid .controlframe.lgrplabel -row 33 -column 1 -sticky w
	grid .controlframe.lgrp      -row 33 -column 2 -sticky w

	grid .controlframe.destlabel -row 34 -column 1 -sticky w
	grid .controlframe.dest      -row 34 -column 2 -sticky w


	frame .controlframe.separator2 -relief raised -height 6 -bd 3
	grid .controlframe.separator2 -row 38 -column 0 -columnspan 4 -sticky ew
	grid rowconfigure .controlframe 38 -minsize 20

	grid rowconfigure .controlframe 39 -minsize 20

	frame .controlframe.sendbox
	grid .controlframe.sendbox -row 40 -column 1 -columnspan 5 -sticky news

	button .controlframe.sendbox.send -text "Send" -command send_settings
	grid .controlframe.sendbox.send -row 1 -column 1 -columnspan 1 -padx 20 -sticky w

	button .controlframe.sendbox.revert -text "Revert to Defaults" -command settings_gui_common_reset_defaults
	grid .controlframe.sendbox.revert -row 1 -column 2 -columnspan 1 -padx 20 -sticky w

	frame .controlframe.sendbox.autosend -relief ridge -borderwidth 4
	label .controlframe.sendbox.autosend.r -textvariable SettingsVar(autosend,remaininglbl)
	checkbutton .controlframe.sendbox.autosend.b -text "Auto Send" -variable SettingsVar(autosend,enabled) -command {
	    global SettingsVar
	    if {$SettingsVar(autosend,enabled) > 0 && $SettingsVar(autosend,interval) > 0} {
		set SettingsVar(autosend,remaining) 200
		set SettingsVar(autosend,remaininglbl) "($SettingsVar(autosend,remaining) remaining)"
		after 100 auto_send_settings
	    }
	}
	label .controlframe.sendbox.autosend.l -text "Interval: "
	entry .controlframe.sendbox.autosend.e -textvariable SettingsVar(autosend,interval) -width 5

	label .controlframe.sendbox.autosend.mseclbl -text "msec"
	grid .controlframe.sendbox.autosend.b -row 0 -column 0 -columnspan 2 -sticky w
	grid .controlframe.sendbox.autosend.r -row 0 -column 2 -columnspan 2 -sticky w
	grid .controlframe.sendbox.autosend.l .controlframe.sendbox.autosend.e .controlframe.sendbox.autosend.mseclbl -sticky w
	grid .controlframe.sendbox.autosend -row 1 -column 3 -columnspan 1 -padx 20 -sticky w

	grid rowconfigure .controlframe 90 -minsize 20

    } else {
	button .controlframe.send -text "Send" -command send_settings
	grid .controlframe.send -row 30 -column 0 -columnspan 2 -sticky w
    }

    pack .controlframe

    settings_gui_common_reset_defaults
}

proc settings_gui_common_generate_packet {} {
    global SettingsVar

    set pkt(dest) ff

    set SettingsVar(autosend,interval,lastsend) $SettingsVar(autosend,interval)

    if {[catch {
	if {$SettingsVar(ttl) > 255} {
	    set SettingsVar(ttl) 12
	} elseif {$SettingsVar(ttl) < 0} {
	    set SettingsVar(ttl) 12
	}
	set pkt(ttl) [format "%02x" $SettingsVar(ttl)]
    } err]} {
	puts "error converting ttl..."
	set SettingsVar(ttl) 0
	set pkt(ttl) 0c
    }
    #puts "Sending ttl: 0x$pkt(ttl)"

    if {[catch {
	if {$SettingsVar(dest) > 255} {
	    set SettingsVar(dest) 255
	} elseif {$SettingsVar(dest) < 0} {
	    set SettingsVar(dest) 255
	}
	set pkt(dest) [format "%02x" $SettingsVar(dest)]
    } err]} {
	puts "error converting dest..."
	set SettingsVar(dest) 255
	set pkt(dest) ff
    }
    #puts "Sending to Destination: 0x$pkt(dest)"

    if {[catch {
	set decimal_lg [format %d "0x$SettingsVar(localgroup)"]
	if {$decimal_lg > 255} {
	    set decimal_lg 255
	} elseif {$decimal_lg < 0} {
	    set decimal_lg 255
	}
	set pkt(localgroup) [format "%02x" $decimal_lg]
	set SettingsVar(localgroup) $pkt(localgroup)
    } err]} {
	puts "error: converting localgroup to 7d..."
	set SettingsVar(localgroup) 7d
	set pkt(localgroup) 7d
    }


    #puts "Packet Type: 0x$SettingsVar(type)"

    settings_gui_common_calc_payload
    set mhoplen $SettingsVar(payload,size)
    set pktlen [expr 8+$mhoplen]
    set pkt(pktlen)  [format "%02x" $pktlen]
    set pkt(mhoplen) [format "%02x" $SettingsVar(payload,size)]
    if {$mhoplen > 0} {
	set pkt(payld) ""
    } else {
	set pkt(payld) ""
    }
    for {set i 0} {$i < $mhoplen} {incr i} {
	append pkt(payld) " [format "%02x" [lindex $SettingsVar(payload,list) $i]]"
    }




    global pktfmt

    set packet ""
    set start 0
    
    puts "pktlen = $pktlen"

    for {set i $start} {$i < $SettingsVar(msgsize)+7} {incr i} {
	#puts -nonewline "i=$i "
	if {$i == $pktfmt(P_DEST)} {
	    append packet "ff ff"
	    incr i
	} elseif {$i == $pktfmt(P_TYPE)} {
	    append packet " [format "%02x" $pktfmt(T_FLOOD)]"
	} elseif {$i == $pktfmt(P_GROUP)} {
	    append packet " $pkt(localgroup)"
	} elseif {$i == $pktfmt(P_LEN)} {
	    append packet " $pkt(pktlen)"
	} elseif {$i == $pktfmt(P_SNDR)} {
	    append packet " fd"
	} elseif {$i == $pktfmt(P_SEQ)} {
	    # Send a random sequence number to make flooding work (flood cache)
	    set randseq [format "%02x" [expr int(rand() * 255)]]
	    append packet " $randseq"
	} elseif {$i == $pktfmt(P_MHOPSNDR)} {
	    append packet " fd"
	} elseif {$i == $pktfmt(P_MHOPDEST)} {
	    append packet " $pkt(dest)"
	} elseif {$i == $pktfmt(P_MHOPAPP)} {
	    append packet " [format "%02x" $pktfmt(C_SETTINGS)]"
	} elseif {$i == $pktfmt(P_MHOPLEN)} {
	    append packet " $pkt(mhoplen)"
	} elseif {$i == $pktfmt(P_FLOODSEQ)} {
	    # Send a random sequence number to make flooding work (flood cache)
	    set randseq [format "%02x" [expr int(rand() * 255)]]
	    append packet " $randseq"
	    #puts "floodseq: $randseq -- $i"
	} elseif {$i == $pktfmt(P_FLOODTTL)} {
	    append packet " $pkt(ttl)"
	} elseif {$i == $pktfmt(P_FLOODDATA) && $mhoplen > 0} {
	    append packet "$pkt(payld)"
	    incr i [expr $mhoplen - 1]
	} else {
	    #puts -nonewline "fell=$i "
	    append packet " 00"
	}
    }

    set packet [string trimleft $packet]
    #puts $packet
    return $packet
}

proc send_settings {} {
    global SettingsVar

    set packet [settings_gui_common_generate_packet]

    #puts -nonewline "b"
    #flush stdout
    incr SettingsVar(settings,sendcnt)
    #puts "Sending settings packet $SettingsVar(settings,sendcnt)"

    uartserver_connector_send $packet

    set SettingsVar(firstsenddone) 1
    #settings_gui_common_change_reset
}


proc auto_send_settings {} {
    global SettingsVar


    if {$SettingsVar(autosend,enabled) > 0 && $SettingsVar(autosend,interval) > 0} {
	set waitval [expr $SettingsVar(autosend,interval) * $SettingsVar(autosend,mult)]

	#minimul interval 100ms
	if {$waitval < 100} {
	    set SettingsVar(autosend,interval) 100
	    set waitval 100
	}

	if {$waitval > 1000} {
	    set waitval [expr ($waitval-500) + int(rand() * 1000)]
	}

	if {$SettingsVar(autosend,remaining) > 0} {
	    incr SettingsVar(autosend,remaining) -1
	    set SettingsVar(autosend,remaininglbl) "($SettingsVar(autosend,remaining) remaining)"
	    update idletasks

	    if {$waitval > 50} {
		after $waitval auto_send_settings
	    } else {
		after 50 auto_send_settings
	    }
	}
	
	set count 1
	if {$waitval > 1000} {
	    set count 5
	}

	for {set i 0} {$i < $count} {incr i} {
	    #puts "sending settings..."
	    send_settings 
	    after 50
	}

    }
    
    if {0 == 1} {
    set lastupdatecnt 0
    while {$SettingsVar(autosend,enabled) > 0 && $SettingsVar(autosend,interval) > 0} {
	set waitval [expr $SettingsVar(autosend,interval) * $SettingsVar(autosend,mult)]

	#minimul interval 100ms
	#if {$waitval < 100} {
	#    set SettingsVar(autosend,interval) 100
	#    set waitval 100
	#}

	set origintv $SettingsVar(autosend,interval)
	set origmult $SettingsVar(autosend,mult)

	#Add +/- 500ms randomization if the send interval > 1sec
	if {$waitval > 1000} {
	    set waitval [expr ($waitval-500) + int(rand() * 1000)]
	}

	#Split the wait into increments of 100ms
	while {$waitval > 0} {
	    if {$waitval > 100} {
		set timelapse 100
		incr lastupdatecnt 0
		set waitval [expr $waitval - $timelapse]
	    } else {
		set timelapse $waitval
		set waitval 0
	    }
	    after $timelapse

	    incr lastupdatecnt $timelapse
	    #puts "$lastupdatecnt"
	    
	    #update gui events every 200ms
	    if {$lastupdatecnt > 5000} {
		#puts -nonewline "updating after $lastupdatecnt ms... "
		#flush stdout
		set lastupdatecnt 0
		#update idletasks
		#update
		#after 1000
		#puts "done"
		#flush stdout
	    }
	    
	    if {$SettingsVar(autosend,enabled) == 0 || $SettingsVar(autosend,interval) != $origintv || $SettingsVar(autosend,mult) != $origmult} {
		set waitval -1
	    }
	}

	# send the value unless interval or send_enabled changed in gui
	if {$waitval >= 0} {
	    #puts -nonewline "n"
	    #flush stdout

	    send_settings 
	}
    }
    
    #puts -nonewline "u $lastupdatecnt ms " 
    #flush stdout

    #update

    #puts -nonewline "p"
    #flush stdout

    after 500 auto_send_settings
    }
}

#proc settings_gui_common_change_reset {} {
#    global SettingsVar
#
#    set SettingsVar(foundchange) 0
#    .controlframe.setverlabel configure -fg black
#    after 100 settings_gui_common_check_value_change
#}

#proc settings_gui_common_change_detected {} {
#    global SettingsVar
#
#    set SettingsVar(foundchange) 1
#    .controlframe.setverlabel configure -fg red
#    
    #puts "change found... new settings number needed"
#    
#    if {$SettingsVar(setver,autoincr,enabled) > 0 && $SettingsVar(foundchange) > 0} {
#	settings_gui_common_increment_setver
#    }
#}

proc settings_gui_common_check_value_change {} {
    global SettingsVar
    
    if {$SettingsVar(firstsenddone) > 0  &&  $SettingsVar(setver) == $SettingsVar(setver,lastsend)} {
	set found_change 0

	if {$found_change == 0} {
	    for {set i 0} {$i < $SettingsVar(settings,cnt)} {incr i} {
		if {$SettingsVar(settings,$i,send) != $SettingsVar(settings,$i,send,lastsend)} {
		    set found_change 1
		    break
		} elseif {$SettingsVar(settings,$i,val) != $SettingsVar(settings,$i,val,lastsend)} {
		    set found_change 1
		    break
		}
	    }
	}
	
	if {$found_change > 0} {
	    settings_gui_common_change_detected
	} else {
	    after 100 settings_gui_common_check_value_change
	}
    }

    #if {($SettingsVar(autosend,interval) != $SettingsVar(autosend,interval,lastsendval)) && $SettingsVar(autosend,enabled) > 0} {
	#after 100 auto_send_settings
    #}
}
