source smoketest/testfuns.gdb
undisplay
set var $nMsgs='PingPongM$nMsgSmoke'
set var $len=10
set var $maxlen=28

#
# runtest len
#
# send packets with payload length 'len'
#
define runtest

       delete breakpoints

       # have to set length after initialization, otherwise it is always 
       # reset (as any c variable would be)
       break 'PingPongM$StdControl$init'
       cont
       set 'PingPongM$length' = $arg0
       break 'PingPongM$finished_test' 
       cont
end


while $len <= $maxlen 
      shell echo "Testing for length :"
      p $len
      runtest $len
      set var $len = $len + 1
      
# check that correct nb messages sent/received
      check $nMsgs

      if $testOK == 0
	  finish_fail
      end
      reset
end


finish_pass