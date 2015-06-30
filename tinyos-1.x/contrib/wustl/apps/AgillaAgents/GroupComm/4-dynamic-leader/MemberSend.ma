// discover the leader location
		loc
		pushn abc	// group name = "abc"
		pushn req
		pushc 3
		pushloc uart_x uart_y
		rout		// send request message: <"req", "abc", loc>
		
		pushc 8		// sleep for 1 second to allow BS to generate reponse
		sleep

// register reaction for leader broadcast message		
		pusht value
		pushn lbm
		pushc 2
		pushc RXN_FIRED
		regrxn	
		
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

// send a member broadcast message every second
LOOP		pushc 31
		pushn mbm
		pushc 2
		getvar 0
		rout			// insert tuple <"mbm", 31> on leader's mote
		pushc 8
		sleep
		rjump LOOP		

RXN_FIRED	remove			// remove the tuple
		pop			// pop field count
		pop			// pop "lbm"
		putled
		endrxn
