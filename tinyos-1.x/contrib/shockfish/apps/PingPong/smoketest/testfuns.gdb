set var $testOK=1

#
# sing a happy tune, the test is finished
#
define beep_finished
 shell beep -f 750; beep -f 900; beep -f 1100; beep -f 1200
end

#
# sing a sad tune, there was an error
#
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

#
# print_macstats
#
# prints mac statistics
#
define print_macstats
       shell echo ""

       shell echo "Radio driver counters:"
       printf "Packets Transmitted: %d\n", 'XE1205RadioM$stats.pktsTX'	
       printf "Packets Received: %d\n", 'XE1205RadioM$stats.pktsRX'	
       printf "CRC Errors: %d\n", 'XE1205RadioM$stats.crcErrsRX'	
end

#
# check X
#
# verify that the node has transmitted and received X messages, and no messages received with errors.
# if either condition is not met, $testOK is set to 0
#
define check
	set var $pktsTX='XE1205RadioM$stats.pktsTX'
	set var $pktsRX='XE1205RadioM$stats.pktsRX'
	set var $crcErrsRX='XE1205RadioM$stats.crcErrsRX'


	if $pktsTX != $arg0
		printerr "Node did not send 10 packets!!"
		set var $testOK=0
	end

	if $pktsRX != $arg0
	        printerr "Node did not receive 10 packets!!"
		set var $testOK=0
	end

	if $crcErrsRX != 0
		printerr "Node received some packets with CRC errors!!"
		set var $testOK=0
	end
end



define finish_pass

	   shell echo ""
	   shell echo ""
	   shell echo "========================"
	   shell echo "| "
	   shell echo "|    Test passed."
	   shell echo "|"
	   shell echo "========================"

	   quit	
end


define finish_fail
	   print_macstats

	   shell echo ""
	   shell echo ""
	   shell echo "XXXXXXXXXXXXXXXXXXXXXXXX"
	   shell echo "X "
	   shell echo "X    Test FAILED!"
	   shell echo "X"
	   shell echo "XXXXXXXXXXXXXXXXXXXXXXXX"

	   quit
end


# XXX this should really go in some general lib file in tools/gdb or stg like that.
define reset
       monitor reset
       flushregs
end