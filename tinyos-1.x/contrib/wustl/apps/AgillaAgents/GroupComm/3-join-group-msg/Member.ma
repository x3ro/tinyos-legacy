// register with the leader
		loc
		pushn jng
		pushc 2
		pushloc 1 1
		rout

// register reaction for leader broadcast messages
		pusht value
		pushn lbm
		pushc 2
		pushc RXN_FIRED
		regrxn
		wait

RXN_FIRED	remove			// remove the tuple
		pop			// pop field count
		pop			// pop "lbm"
		putled
		endrxn