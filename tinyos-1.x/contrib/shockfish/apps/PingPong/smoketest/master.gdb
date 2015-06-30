source smoketest/testfuns.gdb

undisplay


break 'PingPongM$finished_test' 
cont

set var $nMsgs='PingPongM$nMsgSmoke'


# check that correct nb messages sent/received
check $nMsgs

if $testOK == 0
	finish_fail
else
        finish_pass
end