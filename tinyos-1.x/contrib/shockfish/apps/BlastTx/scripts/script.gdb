undisplay

# replicated in testfuns.gdb
define beep_finished
 shell beep -f 750; beep -f 900; beep -f 1100; beep -f 1200
end

# replicated in testfuns.gdb
define beep_error
 shell beep -f 300; beep -f 200
end

#
# printerr s
#
# prints error message with string s
#
define printerr
       shell echo ""
       shell echo Error: $arg0 
       shell echo ""
end




# printinfo pktlen testduration
define printinfo
 	set var $pktsTX = 'XE1205RadioM$stats.pktsTX'
 	set var $bytesTX = 'XE1205RadioM$stats.bytesTX'
	set var $theo_bytesTX = $pktsTX * ( $arg0 + 8 + 6)
	set var $thruput_bits = ($bytesTX * 8) / $arg1
	set var $thruput_pkts = $pktsTX / $arg1

	printf "Pkts sent: %d\n", $pktsTX
	printf "Bytes sent: %d  (Expected bytes sent: %d)\n", $bytesTX, $theo_bytesTX
	printf "Thruput: %d [pkts/s],   %d [bits/s]\n", $thruput_pkts, $thruput_bits
end

break 'BlastTxM$finished_test' 
cont

printinfo 30 120

if 'BlastTxM$senddonefailed' == 1
 printerr "Senddone failed!"
# beep_error
 quit
end

if 'BlastTxM$sendfailed' == 1
 printerr "Send failed!"
# beep_error
# quit
end


#beep_finished
