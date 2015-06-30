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

proc soigui_register_adjuvant {addr {spherecolor ""} {sink 0}} {
    global SoiVar

    #puts "register_adjuvant $addr"

    if {[lsearch $SoiVar(adjuvant,list) $addr] != -1} {
	#this node is already an adjuvant node
	return
    }

    if {$spherecolor == ""} {
	set spherecolor [soigui_getcolor]
    }

    if {[lsearch $SoiVar(adjuvant,list) $addr] == -1} {
	lappend SoiVar(adjuvant,list) $addr
	set SoiVar(adjuvant,$addr,color) $spherecolor
	set SoiVar(node,$addr,color) $spherecolor
	soigui_setnodecolor $addr $spherecolor
	#if {$sink > 0} {
	    soigui_setringcolor $addr $spherecolor
	#}
	soigui_set_possible_sphere_colors $addr $SoiVar(node,$addr,color) $SoiVar(node,$addr,color)
    }
}

proc soigui_getcolor {} {
    global SoiVar

    if {$SoiVar(color,adj,total) > 0} {
	set color_index [expr $SoiVar(color,adj,cnt) % $SoiVar(color,adj,total)]
	set c $SoiVar(color,adj,$color_index)
    } else {
	#this shouldn't happen
	set c black
    }

    incr SoiVar(color,adj,cnt)
    return $c
}

proc soigui_addcolor {color} {
    global SoiVar

    set SoiVar(color,adj,$SoiVar(color,adj,total)) $color
    incr SoiVar(color,adj,total)
}

proc soigui_nodeisin {addr adj1 {adj2 ""}} {
    global SoiVar

    #puts "soigui_nodeisin $addr $adj1 $adj2 -- adjuvant $SoiVar(node,${addr},adjuvant)"

    set update(needed) 0
    
    if {$adj1 == ""  &&  $adj2 == ""} {
	return
    }

    #puts "    nodeisin $addr,$adj1,$adj2 - $SoiVar(node,${addr},adjuvant)"

    if {![info exists SoiVar(adjuvant,$adj1,color)]} {
	puts "soigui_nodeisin: Error: no color registered for adjuvant node $adj1"
    }    
    if {$adj2 != ""  &&  ![info exists SoiVar(adjuvant,$adj2,color)]} {
	puts "soigui_nodeisin: Error: no color registered for adjuvant node $adj2"
    }    

    if {$adj2 == ""} {
	#the node is definitely in adj1's sphere

	if {$SoiVar(node,${addr},adjuvant) != $adj1} {
	    #node has changed spheres
	    soigui_eraselinks $addr
	}

	soigui_set_possible_spheres $addr $adj1 $adj1

	set update(needed) 1
	set update(adjuvant) $adj1
    } else {
	#the node is either in adj1's or adj2's sphere
	soigui_set_possible_spheres $addr $adj1 $adj2
	if {$SoiVar(node,${addr},adjuvant) == $adj1  ||  $SoiVar(node,${addr},adjuvant) == $adj2} {
	    #node is probably in the same sphere, but can't tell for sure

	} else {
	    #node has changed spheres, but can't tell which one it is in
	    soigui_eraselinks $addr

	    set update(needed) 1
	    set update(adjuvant) ""
	}
    }

    if {$update(needed) > 0} {
	soigui_change_sphere $addr $update(adjuvant)
    }
}

proc soigui_set_possible_spheres {addr adj1 adj2} {
    global SoiVar

    if {$adj1 == "" && $adj2 == ""} {
	set c1 $SoiVar(color,unknown)
	set c2 $SoiVar(color,unknown)
    } elseif {$adj1 == $adj2} {
	set c1 $SoiVar(node,$addr,color)
	set c2 $SoiVar(node,$addr,color)
    } else {
	set c1 $SoiVar(adjuvant,$adj1,color)
	if {$adj2 != ""} {
	    set c2 $SoiVar(adjuvant,$adj2,color)
	} else {
	    set c2 $SoiVar(color,unknown)
	}
    }

    soigui_set_possible_sphere_colors $addr $c1 $c2
}

proc soigui_change_sphere {addr adjuvant {recurse 0}} {
    global SoiVar

    if {$SoiVar(node,$addr,adjuvant) == $adjuvant ||  $addr == $adjuvant} {
	#same
	return
    }

    set update(adjuvant,old) $SoiVar(node,$addr,adjuvant)

    #for {set i 0} {$i < $recurse} {incr i} {
	#puts -nonewline "\t"
    #}
    #puts "change_sphere $addr from $SoiVar(node,$addr,adjuvant) to $adjuvant"

    set SoiVar(node,$addr,adjuvant) $adjuvant

    if {$SoiVar(displayMetric) == 0  ||  $SoiVar(metric,currentMetric) == "sphere"} {
	if {$adjuvant != ""} {
	    soigui_setringcolor $addr $SoiVar(adjuvant,$adjuvant,color)
	} else {
	    soigui_setringcolor $addr $SoiVar(color,unknown)
	}
    }

    if {$recurse > 0  &&  $update(adjuvant,old) != $adjuvant} {
	#Just assuming this node belongs to same sphere as next hop
	# didn't actually see a packet that told me this is the case, so color
	# possible spheres as unknown
	soigui_set_possible_spheres $addr "" ""
    }
    
    #update nodes upstream from addr, with same old adjuvant node
    foreach node $SoiVar(node,list) {
	if {$SoiVar(node,$node,adjuvant) == $update(adjuvant,old)} {
	    if {$SoiVar(node,$node,link,1) == $addr} {
		soigui_change_sphere $node $adjuvant [expr $recurse + 1]
	    }
	}
    }
}

proc soigui_add_links {addr next1 {next2 ""}} {
    global SoiVar

    if {$next1 == ""  &&  $next2 == ""} {
	return
    }

    #puts "    addlinks $addr,$next1,$next2 - $SoiVar(node,${addr},link,1),$SoiVar(node,${addr},link,2)"

    if {$next2 != ""} {
	#got 2 new links
	#replace existing links with the two new ones
	soigui_eraselinks $addr
	soigui_draw_link $addr $next1 1
	soigui_draw_link $addr $next2 2
    } else {
	#got 1 new link
	if {$SoiVar(node,${addr},link,2) != ""} {
	    #currently have 2 links, so replace the second one
	    soigui_eraselinks $addr $SoiVar(node,${addr},link,2)
	    soigui_draw_link $addr $next1 2
	} else {
	    #replace all
	    soigui_eraselinks $addr
	    soigui_draw_link $addr $next1 1
	    if {$next2 != ""} {
		soigui_draw_link $addr $next2 2
	    }
	}
    }

    #puts "    addlinks $addr,$next1,$next2 - $SoiVar(node,${addr},link,1),$SoiVar(node,${addr},link,2) - done"
}

proc soigui_calc_location {column row} {
    global SoiVar
    set y [expr ($row * $SoiVar(node,spacing)) + 50]
    set x [expr ($column * $SoiVar(node,spacing)) + 50]
    return [list $x $y]
}

proc soigui_draw_node {addr x y} {
    global SoiVar

    set SoiVar(node,${addr},adjuvant) ""
    for {set i 1} {$i <= $SoiVar(maxlinkcnt)} {incr i} {
	set SoiVar(node,${addr},link,$i) ""
    }

    set SoiVar(node,$addr,active) 0

    set SoiVar(node,$addr,color) $SoiVar(color,node)
    set SoiVar(node,$addr,dataAge) [expr (int($SoiVar(metric,dataAge,max)))]
    set SoiVar(node,$addr,energy) 0

    set SoiVar(node,${addr},x) [expr $x + int($SoiVar(node,width) / 2)]
    set SoiVar(node,${addr},y) [expr $y + int($SoiVar(node,width) / 2)]

    .display create oval  $x $y [expr $x + $SoiVar(node,width)] [expr $y + $SoiVar(node,width)] -fill $SoiVar(color,node) -width $SoiVar(ring,width) -outline $SoiVar(color,unknown) \
	    -tags [list node node_$addr]
    .display create text  $SoiVar(node,$addr,x) $SoiVar(node,$addr,y) -text $addr -font "Helvetica -16 bold" \
	    -tags [list nodelbl nodelbl_$addr]
    .display create text  $SoiVar(node,$addr,x) [expr $SoiVar(node,$addr,y) + int($SoiVar(node,width) / 2) + 8] -text "" -font "Helvetica -12 bold" -fill red \
	    -tags [list nodelbl nodelbl_$addr nodelbl_metric nodelbl_metric_$addr]
    #.display create oval  [expr $x - $SoiVar(ring,width)] [expr $y - $SoiVar(ring,width)] [expr $x + $SoiVar(node,width) + $SoiVar(ring,width)] [expr $y + $SoiVar(node,width) + $SoiVar(ring,width)] -fill "" -width $SoiVar(ring,width) -outline white \
	    #-tags [list nodeclr nodeclr_$addr]

    #Automatically adjust window size to accomodate node locations
    set maxx [expr $x + $SoiVar(node,width) + 100]
    set maxy [expr $y + $SoiVar(node,width) + 100]
    set update_size 0
    if {$maxx > $SoiVar(gui,width)} {
	if {$maxx > 1600} {
	    set maxx 1600
	}

	set SoiVar(gui,width) $maxx
	set update_size 1
    }
    if {$maxy > $SoiVar(gui,height)} {
	if {$maxy > 1600} {
	    set maxy 1600
	}

	set SoiVar(gui,height) $maxy
	set update_size 1
    }
    if {$update_size > 0} {
	puts "Updating window width to $SoiVar(gui,width)x$SoiVar(gui,height) pixels"
	.display configure -width $SoiVar(gui,width) -height $SoiVar(gui,height)
    }

    # possible sphere membership indicators
    set ps(s1,x) [expr $SoiVar(node,$addr,x) - 7]
    set ps(s1,y) [expr $SoiVar(node,$addr,y) + 10] 
    set ps(s2,x) [expr $SoiVar(node,$addr,x) + 3]
    set ps(s2,y) [expr $SoiVar(node,$addr,y) + 10] 
    .display create oval $ps(s1,x) $ps(s1,y) [expr $ps(s1,x) + 4] [expr $ps(s1,y) + 4] -fill $SoiVar(color,node) -width 0 -tags  node_${addr}_s1
    .display create oval $ps(s2,x) $ps(s2,y) [expr $ps(s2,x) + 4] [expr $ps(s2,y) + 4] -fill $SoiVar(color,node) -width 0 -tags  node_${addr}_s2

    .display raise nodelbl_$addr
    if {$SoiVar(show_possible_spheres) > 0} {
	.display raise node_${addr}_s1
	.display raise node_${addr}_s2
    } else {
	.display lower node_${addr}_s1
	.display lower node_${addr}_s2
    }

    lappend SoiVar(node,list) $addr
    incr SoiVar(node,cnt)
}

proc soigui_setnodecolor {addr color} {
    global SoiVar

    #if {$SoiVar(displayMetric) > 0} {
	#.display itemconfigure nodeclr_$addr -outline $color
    #} else {
	soigui_setfillcolor $addr $color
    #}
}

proc soigui_setfillcolor {addr color} {
    .display itemconfigure node_$addr -fill $color

    #make sure node label is readable
    .display raise nodelbl_$addr
}

proc soigui_setmetrictext {addr metric} {
    global SoiVar


    if {$SoiVar(node,$addr,active) == 0} {
	set color black
    } elseif {$SoiVar(node,$addr,stale) > 0} {
	set color red
    } else {
	set color blue
    }

    .display itemconfigure nodelbl_metric_$addr -text $metric -fill $color

    #make sure node label is readable
    .display raise nodelbl_$addr
}

proc soigui_setringcolor {addr color} {
    global SoiVar

    .display itemconfigure node_$addr -outline $color

    #make sure node label is readable
    .display raise nodelbl_$addr
    if {$SoiVar(show_possible_spheres) > 0} {
	.display raise node_${addr}_s1
	.display raise node_${addr}_s2
    } else {
	.display lower node_${addr}_s1
	.display lower node_${addr}_s2
    }
}

proc soigui_set_possible_sphere_colors {addr color1 color2} {
    global SoiVar

    .display itemconfigure node_${addr}_s1 -fill $color1
    .display itemconfigure node_${addr}_s2 -fill $color2
    
    #make sure node label is readable
    .display raise nodelbl_$addr

    if {$SoiVar(show_possible_spheres) > 0} {
	.display raise node_${addr}_s1
	.display raise node_${addr}_s2
    } else {
	.display lower node_${addr}_s1
	.display lower node_${addr}_s2
    }
}


proc soigui_eraselinks {addr {link ""}} {
    global SoiVar

    #puts "   elnk $addr ==> $link"

    if {$link == ""} {
	#Erase all
	.display delete link_$addr
	for {set i 1} {$i <= $SoiVar(maxlinkcnt)} {incr i} {
	    set SoiVar(node,${addr},link,$i) ""
	}
    } else {
	for {set i 1} {$i <= $SoiVar(maxlinkcnt)} {incr i} {
	    if {$SoiVar(node,${addr},link,$i) == $link} {
		.display delete link_${addr}_${link}
		set SoiVar(node,${addr},link,$i) ""
	    }
	}
    }

    #check for errors: 
    # for i > j, if link_i exists, link_j must also exist
    set found 0
    set found_error 0
    for {set i $SoiVar(maxlinkcnt)} {$i >= 1} {incr i -1} {
	if {$SoiVar(node,${addr},link,$i) == ""} {
	    if {$found > 0} {
		set found_error 1
	    }
	} else {
	    set found 1
	}
    }
    if {$found_error > 0} {
	puts "Error in soigui_eraselinks while erasing link $addr ==> $link"
	puts -nonewline "\tlink list: "
	for {set i 1} {$i <= $SoiVar(maxlinkcnt)} {incr i} {
	    puts -nonewline "${i}:$SoiVar(node,${addr},link,$i) "
	    set SoiVar(node,${addr},link,$i) ""
	}
	puts "\n\terasing all to ensure consistency"
	.display delete link_$addr
    }
}


proc soigui_draw_link {node1 node2 {linknum 1}} {
    global SoiVar

    #puts "    drawlinks $node1,$node2,$linknum - $SoiVar(node,$node1,link,1),$SoiVar(node,$node1,link,2)"

    set SoiVar(node,$node1,link,$linknum) $node2

    #Node positions:
    set x1 $SoiVar(node,$node1,x)
    set y1 $SoiVar(node,$node1,y)
    set x2 $SoiVar(node,$node2,x)
    set y2 $SoiVar(node,$node2,y)

    #Arrow positions:
    set offset [expr int($SoiVar(node,width) / 2) - ($SoiVar(ring,width)-1)]
    if {$x1 < $x2} {
	set a_x1 [expr $x1 + $offset]
	set a_x2 [expr $x2 - $offset]
    } elseif {$x1 > $x2} {
	set a_x1 [expr $x1 - $offset]
	set a_x2 [expr $x2 + $offset]
    } else {
	set a_x1 $x1
	set a_x2 $x2
    }
    if {$y1 < $y2} {
	set a_y1 [expr $y1 + $offset]
	set a_y2 [expr $y2 - $offset]
    } elseif {$y1 > $y2} {
	set a_y1 [expr $y1 - $offset]
	set a_y2 [expr $y2 + $offset]
    } else {
	set a_y1 $y1
	set a_y2 $y2
    }

    set color black
    set lwidth 2

    if {[lsearch $SoiVar(adjuvant,list) $node1] != -1  &&  $node2 == 0} {
	#Both are adjuvant nodes, so show stronger link
	set color orange
	set lwidth 5
    }

    .display create line  $a_x1 $a_y1 $a_x2 $a_y2 -width $lwidth -fill $color -arrow last -arrowshape "8 12 6" \
	    -tags [list link link_$node1 link_${node1}_${node2}]

    #puts "    drawlinks $node1,$node2,$linknum - $SoiVar(node,$node1,link,1),$SoiVar(node,$node1,link,2) - done"
}


proc soigui_parse_traceroute {trlist} {
    global SoiVar

    set trlen [llength $trlist]

    # Parse locations of adjuvant nodes in traceroute
    set adj_index_list ""
    for {set i 0} {$i < $trlen} {incr i} {
	set addr [lindex $trlist $i]

	if {![info exists ntbl($addr,A,1)]} {
	    set ntbl($addr,A,1) ""
	    set ntbl($addr,A,2) ""
	    set ntbl($addr,l,1) ""
	    set ntbl($addr,l,2) ""
	    set ntbl($addr,l,cnt) 0
	    lappend nlist $addr
	}

	if {[lsearch $SoiVar(adjuvant,list) $addr] != -1} {
	    lappend adj_index_list $i
	}

	if {$i > 0} {
	    #running normal soi traceroute, with possible routing loops (into and outof a sphere)
	    if {$ntbl($last_addr,l,1) == ""} {
		set ntbl($last_addr,l,1) $addr
	    } else {
		set ntbl($last_addr,l,2) $addr
	    }
	    incr ntbl($last_addr,l,cnt)
	}

	set last_addr $addr
    }
    #foreach addr $nlist {
#	puts " ntbl $addr  A1:$ntbl($addr,A,1) A2:$ntbl($addr,A,2) l1:$ntbl($addr,l,1) l2:$ntbl($addr,l,2)"
#    }
    #puts "adj_index_list: $adj_index_list"
    
    for {set i 0} {$i < [llength $adj_index_list]} {incr i} {
	if {[lindex $adj_index_list $i] > 0} {
	    if {$i == 0} {
		set start 0
		set prevadj ""
	    } else {
		set start [lindex $adj_index_list [expr $i - 1]]
		set prevadj [lindex $trlist $start]
	    }
	    
	    set end [lindex $adj_index_list $i]
	    set nextadj [lindex $trlist $end]

	    #puts "start $start end $end"
	    for {set j $start} {$j < $end} {incr j} {
		set addr [lindex $trlist $j]

		if {$j == $start} {
		    # this is the prevadj, so its adjuvant node is the nextadj
		    set ntbl($addr,A,1) $nextadj
		    set ntbl($addr,A,2) ""
		} elseif {$prevadj == ""} {
		    #Done with node $addr
		    set ntbl($addr,A,1) $nextadj
		    set ntbl($addr,A,2) ""
		} else {
		    if {$ntbl($addr,A,1) == $prevadj  ||  $ntbl($addr,A,2) == $prevadj} {
			set ntbl($addr,A,1) $prevadj
		    } elseif {$ntbl($addr,A,1) == ""} {
			#could be either
			set ntbl($addr,A,1) $prevadj
			set ntbl($addr,A,2) $nextadj
		    } else {
			puts "Error in soigui_parse_traceroute: $addr exists twice, not on both sides of an adjuvant node"
			return
		    }
		}
	    }
	}
    }

    #Check for any invalid node ids
    foreach addr $nlist {
	if {![info exists SoiVar(node,${addr},adjuvant)]} {
	    puts "Error: Node $addr does not exist in gui!  Dropping this traceroute..."
	    return
	}
    }

    foreach addr $nlist {
	#if {$ntbl($addr,l,cnt) > 2} {
	    #puts -nonewline "Warning: link count exceeds 2 ==> " 
	    #puts "  ntbl $addr  A1:$ntbl($addr,A,1) A2:$ntbl($addr,A,2) l1:$ntbl($addr,l,1) l2:$ntbl($addr,l,2) lcnt:$ntbl($addr,l,cnt)" 
	#}
	soigui_nodeisin $addr $ntbl($addr,A,1) $ntbl($addr,A,2)
	soigui_add_links $addr $ntbl($addr,l,1) $ntbl($addr,l,2)
    }

    unset ntbl
}

proc soigui_parse_traceroute_soimesh {trlist} {
    global SoiVar

    set trlen [llength $trlist]

    #If first node after 0 in traceroute is an adjuvant node, assume this is an 802.11 link
    #  The link should be highlighted and all nodes after this link should be in its sphere
    set adjuvant ""
    if {$trlen > 2} {
	set secondtolast [lindex $trlist [expr $trlen - 2]]
	if {[lsearch $SoiVar(adjuvant,list) $secondtolast] != -1} {
	    set adjuvant $secondtolast
	}
    }

    for {set i 0} {$i < $trlen} {incr i} {
	set addr [lindex $trlist $i]

	if {![info exists ntbl($addr,A,1)]} {
	    set ntbl($addr,A,1) ""
	    set ntbl($addr,A,2) ""
	    set ntbl($addr,l,1) ""
	    set ntbl($addr,l,2) ""
	    set ntbl($addr,l,cnt) 0
	    lappend nlist $addr
	}

	if {$i > 0} {
	    #If running soimesh, can't have routing loops, so do a simple next hop link update
	    set ntbl($last_addr,l,1) $addr
	    set ntbl($last_addr,l,cnt) 1
	}

	#By default, a node is in Node 0's sphere
	set ntbl($addr,A,1) 0
	set ntbl($addr,A,2) ""

	if {$i < [expr $trlen - 2]} {
	    if {$adjuvant != ""} {
		set ntbl($addr,A,1) $adjuvant
		set ntbl($addr,A,2) ""
	    }
	}

	set last_addr $addr
    }
    
    foreach addr $nlist {
	#if {$ntbl($addr,l,cnt) > 2} {
	    #puts -nonewline "Warning: link count exceeds 2 ==> " 
	    #puts "  ntbl $addr  A1:$ntbl($addr,A,1) A2:$ntbl($addr,A,2) l1:$ntbl($addr,l,1) l2:$ntbl($addr,l,2) lcnt:$ntbl($addr,l,cnt)" 
	#}
	soigui_nodeisin $addr $ntbl($addr,A,1) $ntbl($addr,A,2)
	soigui_add_links $addr $ntbl($addr,l,1) $ntbl($addr,l,2)
    }

    unset ntbl
}


#proc soigui_remove_link {node1 node2} {
#    global SoiVar
#
#    set name link_${node1}_${node2}
#   #puts "removing $name"
#    set index [lsearch $SoiVar(linklist) $name]
#    if {$index != -1} {
#	set SoiVar(linklist) [lreplace $SoiVar(linklist) $index $index]
#	.display delete $name
#    }
#}


proc print_usage {} {
    global argv0
    puts "Usage: $argv0 \[-r server\] \[-a server\] \[-f packettrace\] \[-p\]"
    puts "\t-r server          Connect to remote server"
    puts "\t-a server          Alternate remote server"
    puts "\t-f packettrace     Load from packet trace file"
    puts "\t-p                 Prompt before applying a new traceroute"
    puts "\t-C                 Show console (windows only)"
    puts "\t-m                 Display metrics"
    puts "\t-bg imagefile      Display background image"
    puts "\t-sp spacing        Set internode spacing (in pixels)"
    puts "\t-t topofile        Import topology layout file"
    puts "\t-o imagefile       Image of 802.11 overlay network"
    puts "\t-dbg               Debug mode"
    exit
}

proc show_overlay_win {filename} {
    if { [winfo exists .overlaywin] } {
        raise .overlaywin
    } else {
        toplevel .overlaywin

        canvas .overlaywin.display
        grid .overlaywin.display -sticky news -columnspan 3
        grid columnconfigure . 1 -weight 1
        grid rowconfigure . 1 -weight 1

        # Add background image
        puts "Reading overlay network image file: $filename"
        image create photo ovimg
        ovimg read $filename
        .overlaywin.display create image 0 0 -anchor nw -image ovimg
        .overlaywin.display configure -width [image width ovimg] -height [image height ovimg]
    }
}

proc soigui_init {} {
    global SoiVar

    global pktfmt
    global pktprt
    global argv

    if {[info exists pktfmt(init)] < 1} {
	packet_format_init 1
    }

    set SoiVar(gui,width) 0
    set SoiVar(gui,height) 0

    set SoiVar(node,cnt) 0
    set SoiVar(node,list) ""

    set SoiVar(colorcnt) 0

    set SoiVar(startaddr) 10
    set SoiVar(rows)      7
    set SoiVar(columns)   5

    set SoiVar(ring,width) 4
    set SoiVar(node,width) 28
    set SoiVar(node,spacing) 50

    set SoiVar(unknownloc,x) [expr 300 / $SoiVar(node,spacing)]
    set SoiVar(unknownloc,y) [expr (2*$SoiVar(node,width)) / $SoiVar(node,spacing)]

    #set SoiVar(linklist) ""

    set SoiVar(adjuvant,list) ""
    set SoiVar(maxlinkcnt) 2

    set SoiVar(prompting) 0
    set SoiVar(displayMetric) 0
    set SoiVar(metric,showtext) 0

    set SoiVar(displayMetric,format) "%2.1f"

    #If 1, show median metric value for all nodes, otherwise show average
    set SoiVar(metric,showMedian) 0

    set SoiVar(nodetimeout) 120.0

    set SoiVar(metric,energy,max) 300.0
    set SoiVar(metric,energy,min) 80.0
    set SoiVar(metric,dataAge,max) 120.0
    set SoiVar(metric,dataAge,min) 10.0
    set SoiVar(metric,currentMetric) "dataAge"

    #colors
    set SoiVar(color,adj,total) 0
    set SoiVar(color,adj,cnt) 0
    #shade of red
    soigui_addcolor "#e03232"
    #shade of light blue
    soigui_addcolor "#7878ec"
    #shade of green
    soigui_addcolor "#32b432"
    #shade of purple
    soigui_addcolor "#c22efe"
    #shade of pink
    soigui_addcolor "#d47676"
    #shade of blue
    soigui_addcolor "#3232b4"
    set SoiVar(color,background) white
    set SoiVar(color,node) wheat
    #set SoiVar(color,unknown) "#444444"
    #set SoiVar(color,unknown) "#2a787a"
    set SoiVar(color,unknown) black
    #set SoiVar(color,sink) "#2a787a"
    set SoiVar(color,sink) orange

    set SoiVar(show_possible_spheres) 0



    # parse command line
    set server_arg ""
    set alt_server ""
    set next_is_ip 0
    set next_is_alt_ip 0
    set next_is_file 0
    set next_is_img 0
    set bgimg_file ""
    set pkttrace_file "-1"
    set next_is_spacing 0
    set next_is_topo 0
    set SoiVar(topology_file) ""
    set next_is_overlay_file 0
    set overlay_file ""
    set show_console 0
    set SoiVar(showSensorVal) 0


    foreach arg $argv {
	global pktprt

	if {$arg == "-r"} {
	    set next_is_ip 1
	} elseif {$next_is_ip == 1} {
	    set server_arg $arg
	    set next_is_ip 0
	} elseif {$arg == "-a"} {
	    set next_is_alt_ip 1
	} elseif {$next_is_alt_ip == 1} {
	    set alt_server $arg
	    set next_is_alt_ip 0
        } elseif {$arg == "-C"} {
            set show_console 1
	} elseif {$arg == "-f"} {
	    set next_is_file 1
	} elseif {$next_is_file == 1} {
	    set pkttrace_file $arg
	    set next_is_file 0
	} elseif {$arg == "-bg"} {
	    set next_is_img 1
	} elseif {$next_is_img == 1} {
	    set bgimg_file $arg
	    set next_is_img 0
	} elseif {$arg == "-dbg"} {
	    set SoiVar(debug) 1
	    set SoiVar(show_possible_spheres) 1
	} elseif {$arg == "-p"} {
	    set SoiVar(prompting) 1
	} elseif {$arg == "-sp"} {
	    set next_is_spacing 1
	} elseif {$next_is_spacing == 1} {
	    set SoiVar(node,spacing) $arg
	    set next_is_spacing 0
	} elseif {$arg == "-t"} {
	    set next_is_topo 1
	} elseif {$next_is_topo == 1} {
	    set SoiVar(topology_file) $arg
	    set next_is_topo 0
	} elseif {$arg == "-m"} {
	    set SoiVar(displayMetric) 1
	} elseif {$arg == "-o"} {
            set next_is_overlay_file 1
	} elseif {$next_is_overlay_file == 1} {
	    set overlay_file $arg
            set next_is_overlay_file 0
	} elseif {$arg == "-sense"} {
           # show sensor values rather than energy
           set SoiVar(showSensorVal) 1
           set SoiVar(metric,energy,max) 1024.0
           set SoiVar(metric,energy,min) 0.0
	} else {
	    puts "invalid arg: $arg"
	    print_usage
	}
    }

	#puts $next_is_ip

    if {$next_is_ip != 0} {
	puts "next_is_ip"
	print_usage
    }

    if {$next_is_alt_ip != 0} {
	puts "next_is_alt_ip"
	print_usage
    }

    if {$next_is_file != 0} {
	puts "next_is_file"
	print_usage
    }

    if {$next_is_img != 0} {
	puts "next_is_img"
	print_usage
    }

    if {$next_is_topo != 0} {
	puts "next_is_topo"
	print_usage
    }

    if {$next_is_spacing != 0} {
	puts "next_is_spacing"
	print_usage
    }

    if {$next_is_overlay_file != 0} {
	puts "next_is_overlay_file"
	print_usage
    }


    if {$server_arg != ""} {
	puts "SoiGUI: Using arg uartserver: $server_arg"
	set server $server_arg
    } else {
	puts "SoiGUI: Using default uartserver: 127.0.0.1"
	set server "127.0.0.1"
    }


    if {$SoiVar(displayMetric) == 1} {
	frame .metricf -relief raised -bd 3
	label .metricf.lbl -text "Current Metric:"

	radiobutton .metricf.age -text "Data Age" -variable SoiVar(metric,currentMetric) -value "dataAge" -command {
	    soigui_update_average_metric_label_colors
	    soigui_update_all_metric_colors
	}
puts "variable is $SoiVar(showSensorVal)"
        if {$SoiVar(showSensorVal) == 1} {
           set text "Sensor Value"
        } else {
           set text "Energy"
        }
	radiobutton .metricf.energy -text $text -variable SoiVar(metric,currentMetric) -value "energy" -command {
	   soigui_update_average_metric_label_colors
	   soigui_update_all_metric_colors
	}
	radiobutton .metricf.sphere -text "Sphere" -variable SoiVar(metric,currentMetric) -value "sphere" -command {
	    soigui_update_average_metric_label_colors
	    soigui_update_all_metric_colors
	}

	label .metricf.showtxtlbl -text "Show Node Values:"
	checkbutton .metricf.showtxtbox -text "" -variable SoiVar(metric,showtext) -command soigui_update_all_metric_colors


	grid .metricf.lbl -row 0 -column 0 -columnspan 2 -sticky w
	grid .metricf.age -row 1 -column 0 -columnspan 2 -sticky w
	grid .metricf.energy -row 2 -column 0 -columnspan 2 -sticky w
	grid .metricf.sphere -row 3 -column 0 -columnspan 2 -sticky w
	grid .metricf.showtxtlbl -row 4 -column 0 -sticky w
	grid .metricf.showtxtbox -row 4 -column 1 -sticky w

	set font "Helvetica -18 bold"

	frame .metricvalf -relief raised -bd 3
	label .metricvalf.lbl -text "Average Metric Values" -font $font

	label .metricvalf.activelbl    -text "Active Nodes: " -font $font
	label .metricvalf.activeval    -textvariable SoiVar(metric,avg,nodecnt) -font $font

	label .metricvalf.agelbl      -text "Data Age: " -font $font
	label .metricvalf.ageval      -textvariable SoiVar(metric,avg,dataAge) -font $font
	label .metricvalf.ageunitslbl -text "(seconds)" -font $font

        if {$SoiVar(showSensorVal) == 1} {
	   label .metricvalf.energylbl      -text "" -font $font
	   label .metricvalf.energyval      -text "" -font $font
	   label .metricvalf.energyunitslbl -text "" -font $font
        } else {
	   label .metricvalf.energylbl      -text "Remaining Lifetime: " -font $font
	   label .metricvalf.energyval      -textvariable SoiVar(metric,avg,energy) -font $font
	   label .metricvalf.energyunitslbl -text "(days)" -font $font
        }

	#label .metricvalf.energylbl -text "Hop Count: "

	grid .metricvalf.lbl -sticky w -columnspan 3
	grid .metricvalf.activelbl .metricvalf.activeval -sticky w
	grid .metricvalf.agelbl .metricvalf.ageval .metricvalf.ageunitslbl -sticky w
	grid .metricvalf.energylbl .metricvalf.energyval .metricvalf.energyunitslbl -sticky w
	grid columnconfigure .metricvalf 5 -weight 1

	grid .metricf -column 0 -row 0 -sticky news
	grid .metricvalf -column 1 -row 0 -sticky news

        if {$alt_server != "" || $overlay_file != ""} {
	   frame .utils -relief raised -bd 3
	   grid .utils -column 2 -row 0 -sticky news
        }

        if {$alt_server != ""} {
	   label .utils.lbl -text "802.11 Overlay"

           set SoiVar(overlay) "disabled"
	   radiobutton .utils.primary -text "Disable" -variable SoiVar(overlay) -value "disabled" -command "uartserver_connector_reconnect $server"
	   radiobutton .utils.secondary -text "Enable" -variable SoiVar(overlay) -value "enabled" -command "uartserver_connector_reconnect $alt_server"

	   grid .utils.lbl -row 0 -column 0 -sticky w
	   grid .utils.primary -row 1 -column 0 -sticky w
	   grid .utils.secondary -row 2 -column 0 -sticky w
        }

        if {$overlay_file != ""} {
           button .utils.showoverlay -text "Show Overlay" -command "show_overlay_win $overlay_file"
           grid .utils.showoverlay -row 3 -column 0 -sticky w
        }


	grid columnconfigure . 1 -weight 1

	soigui_update_average_metric_label_colors
    }

    canvas .display -width $SoiVar(gui,width) -height $SoiVar(gui,height) -bg $SoiVar(color,background)
    grid .display -sticky news -columnspan 3
    grid columnconfigure . 1 -weight 1
    grid rowconfigure . 1 -weight 1

    if {$bgimg_file != ""} {
	# Add background image
	puts "Reading background image file: $bgimg_file"
	image create photo bgimg
	bgimg read $bgimg_file
	set SoiVar(gui,width) [image width bgimg]
	set SoiVar(gui,height) [image height bgimg]
	.display create image 0 0 -anchor nw -image bgimg
	.display configure -width $SoiVar(gui,width) -height $SoiVar(gui,height)
    }

    if {$SoiVar(displayMetric) == 1} {
	
    }

    global tcl_platform
    if {$tcl_platform(platform) == "windows" && $show_console == 1} {
	console show
    }


    if {$SoiVar(topology_file) == ""} {
	soigui_setup_grid_topology
    } else {
	puts "Importing topology file: $SoiVar(topology_file)"
	source $SoiVar(topology_file)
	soigui_update_all_metric_colors
    }


    if {$pkttrace_file != -1} {
	puts "Parsing packet trace file: $pkttrace_file"
	soigui_packet_trace_file_reader $pkttrace_file
	puts "done reading file..."
    } else {
	if {$SoiVar(prompting) > 0} {
	    puts "Error: prompting only works when reading a packet trace"
	    print_usage
	}

	uartserver_connector_init $server soigui_handle_packet
    }

    if {$SoiVar(displayMetric) == 1} {
	after 10 soigui_timer_func
    }
}

proc soigui_check_packet_type {pktname} {
	global pktfmt
	global SoiVar

	upvar 1 $pktname packet
	set retval 0

	if {$packet(type) == $pktfmt(T_DSDV_SOI)  && $packet(mhopapp) == $pktfmt(C_TRACEROUTE_SOI)} {
		set retval 1
	} elseif {$SoiVar(displayMetric) == 1 && $packet(type) == $pktfmt(T_DSDV)  && $packet(mhopapp) == $pktfmt(C_TRACEROUTE)} {
		set retval 1
	}

	return $retval

}

proc soigui_handle_packet {pkt} {
    global SoiVar
    global pktfmt
    if {[parse_packet $pkt packet] == -1} {
	return
    }

    #puts "handle packet $pkt"



    if { [soigui_check_packet_type packet] == 1 } {

	#Hack -- for use when listening with simple gateway
	#if {$packet(soi_dsdvnext) != $packet(mhopdest)} {
	    #puts "Hack: dropping packet"
	#}

	#puts "found T_DSDV_SOI C_TRACEROUTE_SOI"
	set trlist ""
	for {set i 0} {$i < $packet(hop,total)} {incr i} {
	    set addr [format "%d" $packet(hop,$i)]
	    if {$SoiVar(displayMetric) == 0 && $packet(hop,$i,bit) > 0 } {
		soigui_register_adjuvant $addr
	    }

	    if {[lsearch $SoiVar(node,list) $addr] < 0} {
		soigui_draw_node_at $addr $SoiVar(unknownloc,x) $SoiVar(unknownloc,y)
		incr SoiVar(unknownloc,x)
	    }

	    lappend trlist $addr
	}

	set currentTime [clock seconds]

	puts "\[[clock format $currentTime -format "%H:%M:%S"]\]parsing traceroute: $trlist"

	if {$SoiVar(prompting) > 0} {
	    tk_messageBox -message "Ready to parse: $trlist" -type ok
	}



	if {$SoiVar(displayMetric) == 1} {
	    set addr [format "%d" $packet(mhopsndr)]
	    set SoiVar(node,$addr,active) 1
	    set SoiVar(node,$addr,stale) 0
	    set SoiVar(node,$addr,dataAge) 0
	    
            if {$SoiVar(showSensorVal) == 1} {
               puts "Sensor val is $packet(energyval)"
               set SoiVar(node,$addr,energy) $packet(energyval)
            } else {
	      #convert energy to days of remaining battery life, using formula from Mark/Jasmeet
	       if {$packet(energyval) > 0} {
# Use a smaller battery capacity
#		   set SoiVar(node,$addr,energy) [expr 117827.32/$packet(energyval)]
		   set SoiVar(node,$addr,energy) [expr 11782.732/$packet(energyval)]
	       } else {
		  set SoiVar(node,$addr,energy) 0.0
	       }
            }

	    soigui_update_node_metric_color $addr
	    soigui_update_node_metric_value $addr
	    soigui_parse_traceroute_soimesh $trlist
	} else {
	    soigui_parse_traceroute $trlist
	}

	#puts "done with traceroute: $trlist"
    }

    unset packet
    update idletasks
}

proc soigui_packet_trace_file_reader {file} {
    global SoiVar
    puts "Opening file $file"

    set fid [open $file r]

    set linenum 0
    while {1} {
	if {[eof $fid] > 0} {
	    puts "Reached End of File"
	    return
	}

	incr linenum

	gets $fid line
	if {[regexp {^([0-9]+)[^a-fA-F0-9]+([a-fA-F0-9][a-fA-F0-9]( +[a-fA-F0-9][a-fA-F0-9])*)$} $line wholeline tstampstr packet] > 0} {
	    if {[regexp {01\s00\s00\s00\s00\sFF} $line] > 0} {
		puts "Found Reboot packet: $line"
		return
	    }
	    #puts ">> $tstampstr >> $packet"
	    soigui_handle_packet $packet
	    update idletasks
	} else {
	    puts "Skipping Line $linenum: $line"
	}

    }

}


proc soigui_test_add_rand_link {} {
    global SoiVar

    set node1 [expr int(rand() * $SoiVar(node,cnt))]
    set node2 $node1
    while {$node2 == $node1} {
	set node2 [expr int(rand() * $SoiVar(node,cnt))]
    }

    soigui_draw_link $node1 $node2

    after 70 soigui_test_add_rand_link
}

proc soigui_test_remove_rand_link {} {
    global SoiVar

    set node1 [expr int(rand() * $SoiVar(node,cnt))]
    set node2 $node1

    while {$node2 == $node1} {
	set node2 [expr int(rand() * $SoiVar(node,cnt))]
    }

    #soigui_remove_link $node1 $node2
    #soigui_remove_link $node2 $node1

    after 1 soigui_test_remove_rand_link
}


proc soigui_hsvToRgb {hue sat val} {
	set v [expr {round(65535.0*$val)}]
	if {$sat == 0} {
	return [list $v $v $v]
	} else {
		set hue [expr {$hue*6.0}]
		if {$hue >= 6.0} {
		set hue 0.0
	}
	set i [expr {int($hue)}]
	set f [expr {$hue-$i}]
	set p [expr {round(65535.0*$val*(1 - $sat))}]
	set q [expr {round(65535.0*$val*(1 - ($sat*$f)))}]
	set t [expr {round(65535.0*$val*(1 - ($sat*(1 - $f))))}]
	switch $i {
	0 {return [list $v $t $p]}
	1 {return [list $q $v $p]}
	2 {return [list $p $v $t]}
	3 {return [list $p $q $v]}
	4 {return [list $t $p $v]}
	5 {return [list $v $p $q]}
	}
	}
}


proc soigui_get_normalized_metric {addr} {
	global SoiVar

	set val [expr $SoiVar(node,$addr,$SoiVar(metric,currentMetric)) / $SoiVar(metric,$SoiVar(metric,currentMetric),max)]

	if {$SoiVar(node,$addr,$SoiVar(metric,currentMetric)) <= $SoiVar(metric,$SoiVar(metric,currentMetric),min)} {
		set val 0.0
	}

	if {$SoiVar(node,$addr,$SoiVar(metric,currentMetric)) >= $SoiVar(metric,$SoiVar(metric,currentMetric),max)} {
		set val 1.0
	}

	#data age is an inverted metric (lower is better)
	if {$SoiVar(metric,currentMetric) == "dataAge"} {
	    set val [expr 1.0 - $val]
	}

	return $val
}

proc soigui_update_node_metric_color {addr} {
    global SoiVar

    if {$SoiVar(metric,currentMetric) == "sphere" || $addr == 0} {
	if {[info exists SoiVar(node,$addr,color)]} {
	    set color $SoiVar(node,$addr,color)
	} else {
	    set color $SoiVar(color,unknown)
	}
    } else {
	set h .614
   	set s .28
   	set b 1.0

	set metric [soigui_get_normalized_metric $addr]

	if {$metric < .45} {
		set metric .45
	}

	set b $metric

	set color [soigui_listToHexRGB [soigui_hsvToRgb $h $s $b]]

    }

    soigui_setfillcolor $addr $color
}


proc soigui_update_node_metric_value {addr} {
    global SoiVar

    set value ""

    if {$SoiVar(metric,currentMetric) == "sphere" || $addr == 0} {
    } else {
	if {$SoiVar(metric,showtext) > 0} {
	    set value [expr int($SoiVar(node,$addr,$SoiVar(metric,currentMetric)))]
	}
    }

    soigui_setmetrictext $addr $value
}


proc soigui_update_average_metric_label_colors {} {
    global SoiVar

    .metricvalf.agelbl configure -fg black
    .metricvalf.ageval configure -fg black
    .metricvalf.energylbl configure -fg black
    .metricvalf.energyval configure -fg black

    if {$SoiVar(metric,currentMetric) == "dataAge"} {
	.metricvalf.agelbl configure -fg red
	.metricvalf.ageval configure -fg red
    } elseif {$SoiVar(metric,currentMetric) == "energy"} {
	.metricvalf.energylbl configure -fg red
	.metricvalf.energyval configure -fg red
    }

}


proc soigui_update_all_metric_colors {} {
   global SoiVar

   foreach addr $SoiVar(node,list) {
       soigui_update_node_metric_color $addr
       soigui_update_node_metric_value $addr

       if {$SoiVar(displayMetric) == 1  && $SoiVar(metric,currentMetric) == "sphere"} {
	   if {$SoiVar(node,$addr,adjuvant) != ""} {
	       soigui_setringcolor $addr $SoiVar(adjuvant,$SoiVar(node,$addr,adjuvant),color)
	   } else {
	       soigui_setringcolor $addr $SoiVar(color,unknown)
	   }
       } else {
	   if {[lsearch $SoiVar(adjuvant,list) $addr] != -1} {
	       soigui_setringcolor $addr $SoiVar(adjuvant,$addr,color)
	   } else {
	       soigui_setringcolor $addr $SoiVar(color,unknown)
	   }
       }
   }
}

proc soigui_update_average_metric_value {metric} {
    global SoiVar
    
    set sum 0.0
    set cnt 0
    set vallist ""

    foreach addr $SoiVar(node,list) {
	if {$SoiVar(node,$addr,active) > 0} {
	    set value $SoiVar(node,$addr,$metric)

	    #if {$SoiVar(node,$addr,dataAge) >= $SoiVar(metric,dataAge,max)} {
		#if {$SoiVar(node,$addr,stale) < 1} {
		#    puts "Node $addr has become stale"
		#}
		#set SoiVar(node,$addr,stale) 1
		#if {$metric == "dataAge"} {
		#    set value $SoiVar(metric,dataAge,max)
		#}
	    #}

	    #puts "Metric: $metric Addr:$addr Value: $value"

	    if {$SoiVar(node,$addr,dataAge) < $SoiVar(nodetimeout)} {
		set sum [expr $sum + $value]
		set vallist [linsert $vallist 0 $value]
		incr cnt
	    } else {
		set SoiVar(node,$addr,active) 0
		puts "Node $addr has timed out"
		soigui_eraselinks $addr
	    }
	}
    }
    
    set summaryval " --- "

    if {$SoiVar(metric,showMedian) > 0} {
	#Computer the median
	set vallist [lsort -real -increasing $vallist]
	set mid [expr int($cnt/2.0)]
	#puts "cnt: $cnt mid: $mid vallist: $vallist"
	if {[expr $cnt % 2] != 0} {
	    set summaryval [format $SoiVar(displayMetric,format) [lindex $vallist $mid]]
	} else {
	    if {$cnt > 1} {
		set a [lindex $vallist $mid]
		set b [lindex $vallist [expr $mid - 1]]
		set summaryval [format $SoiVar(displayMetric,format) [expr ($a + $b)/2.0]]
	    }
	}
	
    } else {
	#Compute the average
	if {$cnt > 0} {
	    set summaryval [format $SoiVar(displayMetric,format) [expr double($sum) / double($cnt)]]
	}
    }

    set SoiVar(metric,avg,$metric) $summaryval
    set SoiVar(metric,avg,nodecnt) $cnt
}

proc soigui_update_all_average_metric_values {} {
    foreach metric [list dataAge energy] {
	soigui_update_average_metric_value $metric
    }
}

proc soigui_timer_func {} {
   global SoiVar

   foreach addr $SoiVar(node,list) {
	if {$SoiVar(node,$addr,active) > 0} {
	    incr SoiVar(node,$addr,dataAge)
	}
	soigui_update_node_metric_color $addr
	soigui_update_node_metric_value $addr
   }

   soigui_update_all_average_metric_values

   after 1000 soigui_timer_func

}

proc soigui_listToHexRGB {rgb} {
	 set red [expr int(([lindex $rgb 0] / 65535.0) * 255.0)]
	 set green [expr int(([lindex $rgb 1] / 65535.0) * 255.0)]
	 set blue [expr int(([lindex $rgb 2] / 65535.0) * 255.0)]

	 #puts "rgb: $rgb"
	 #puts "Red: $red, Green: $green, Blue: $blue"

	 set result "#[format "%02x" $red][format "%02x" $green][format "%02x" $blue]"
	 #puts "$result"
	 return $result

}

proc soigui_draw_node_at {addr x y} {
	global SoiVar
	set xpix [expr ($x * $SoiVar(node,spacing) - int($SoiVar(node,width) / 2.0))]
	set ypix [expr ($y * $SoiVar(node,spacing) - int($SoiVar(node,width) / 2.0))]

	soigui_draw_node $addr $xpix $ypix
	soigui_setfillcolor $addr [soigui_listToHexRGB [soigui_hsvToRgb .614 .28 1]]
}


proc soigui_setup_arb_topology {} {
    #Note: this now gets imported from a topology file.
    #Following is sample of what should go in a topo file.

    soigui_draw_node_at 10 2 0
    soigui_draw_node_at 11 2 1
    soigui_draw_node_at 15 2 2

    soigui_draw_node_at 18 2 3

    soigui_draw_node_at 19  1 3.5
    soigui_draw_node_at 0   0.2 3.5


    soigui_draw_node_at 20 2 5

    soigui_draw_node_at 44 5 8

    soigui_draw_node_at 23 2 6
    soigui_draw_node_at 41 4 6

    soigui_draw_node_at 25 2 7
    soigui_draw_node_at 40 4 7

    soigui_draw_node_at 26 2 8
    soigui_draw_node_at 39 4 8

    soigui_draw_node_at 27 2 9
    soigui_draw_node_at 38 4 9

    soigui_draw_node_at 31 2 10
    soigui_draw_node_at 35 4 10

    soigui_draw_node_at 32 2 11
    soigui_draw_node_at 33 4 11

    soigui_draw_node_at 24 5 12


    soigui_register_adjuvant 0 $SoiVar(color,sink) 1
    soigui_register_adjuvant 10
    soigui_register_adjuvant 44 
    soigui_register_adjuvant 24 
}


proc soigui_setup_grid_topology {} {
    global SoiVar
    set addr $SoiVar(startaddr)
    for {set j 0} {$j < $SoiVar(columns)} {incr j} {
	for {set i 0} {$i < $SoiVar(rows)} {incr i} {
	    set loc [soigui_calc_location [expr ($SoiVar(columns) - 1) - $j] [expr ($SoiVar(rows)-1) - $i]]
	    soigui_draw_node $addr [lindex $loc 0] [lindex $loc 1]
	    incr addr
	}
    }

    #Gateway Node
    set loc [soigui_calc_location [expr $SoiVar(columns) / 2] $SoiVar(rows)]
    soigui_draw_node 0 [lindex $loc 0] [lindex $loc 1]
    soigui_register_adjuvant 0 $SoiVar(color,sink) 1
}

proc soigui_test {} {
    #    soigui_register_adjuvant 8
    #    soigui_register_adjuvant 27
    #    soigui_nodeisin 7 8
    #    soigui_nodeisin 9 8
    #    soigui_nodeisin 10 8
    #    soigui_nodeisin 26 27
    #soigui_draw_link 7 15
    #soigui_draw_link 7 4
    #soigui_draw_link 8 15
    #after 10000 soigui_eraselinks 7

    #    soigui_add_links 10 9 16

    #after 5000 soigui_nodeisin 10 27
#    after 5000 soigui_add_links 10 17
    #after 5000 soigui_add_links 10 6 17

    #after 100 soigui_test_add_rand_link
    #after 50  soigui_test_remove_rand_link



    #soigui_register_adjuvant 0
    #soigui_register_adjuvant 9
    #soigui_register_adjuvant 13

    #soigui_parse_traceroute [list 22 21 14 13 7 0]
    #soigui_parse_traceroute [list 1 7 13 7 0]

    #after 5000 {soigui_parse_traceroute [list 8 7 0]}
    #after 10000 {soigui_parse_traceroute [list 14 8 7 0]}

    #soigui_register_adjuvant 16
    #soigui_register_adjuvant 23
    #soigui_register_adjuvant 30
}


lappend auto_path .

soigui_init

soigui_test
