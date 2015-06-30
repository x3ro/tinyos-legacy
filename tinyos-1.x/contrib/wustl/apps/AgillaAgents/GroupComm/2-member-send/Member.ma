		pusht value
		pushn lbm
		pushc 2
		pushc RXN_FIRED
		regrxn			// register reaction for leader broadcast message
		wait

RXN_FIRED	remove			// remove the tuple
		pop			// pop field count
		pop			// pop "lbm"
		putled
		endrxn