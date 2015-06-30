// register reaction for messages to send		
		pusht string
		pusht string
		pusht string
		pushc 3
		pushc SND_MSG
		regrxn
WAIT		wait

SND_MSG		remove
		pop		// pop number of fields
		pop		// "snd"
		pop		// string
		pop		// string
		pushc 25
		putled		// toggle red LED
		clear
		pushc WAIT	// ****** DEBUG  why is this necessay?
		endrxn