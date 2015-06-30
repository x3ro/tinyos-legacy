		pusht value
		pushn lbm
		pushc 2
		pushc RXN_FIRED
		regrxn			// register reaction for leader broadcast message

// send a member broadcast message every second
LOOP		pushc 31
		pushn mbm
		pushc 2
		pushloc 1 1
		rout			// insert tuple <"mbm", 31> on leader's mote
		pushc 8
		sleep
		rjump LOOP		

RXN_FIRED	remove			// remove the tuple
		pop			// pop field count
		pop			// pop "lbm"
		putled
		endrxn