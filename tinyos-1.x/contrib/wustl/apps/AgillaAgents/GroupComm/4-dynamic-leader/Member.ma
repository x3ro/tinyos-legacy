// discover the leader location
		loc
		pushn abc	// group name = "abc"
		pushn req
		pushc 3
		pushloc uart_x uart_y
		rout		// send request message: <"req", "abc", loc>

		pushc 8		// sleep for 1 second to allow BS to generate reponse
		sleep
		
		pusht location
		pushn grl
		pushc 2
		
		in 		// wait for response
		pop
		pop
		setvar 0	// heap[0] = leader location
		
// register with the leader
		loc
		pushn jng
		pushc 2
		getvar 0
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
