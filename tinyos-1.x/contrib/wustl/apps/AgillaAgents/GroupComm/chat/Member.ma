// get use rname from cmd line
// store user name in heap[0]
//		pushn fei
//		setvar 0

// Send a string to the base station to create GUI
// 'msc', agentID, screen name
		getvar	0
		aid
		pushn	msc
		pushc	3
		pushloc	force_uart_x force_uart_y
		rout

pushc 8
sleep

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
		setvar 1	// heap[1] = leader location
		
// register with the leader
		loc
		aid
		pushn jng
		pushc 3
		getvar 1
		rout

// register reaction for leader broadcast messages
		pusht string
		pusht string
		aid
		pushn lbm
		pushc 4
		pushcl RXN_FIRED
		regrxn

// register reaction for messages to send		
		pusht string
		getvar 0		// name of agent
		aid
		pushn snd
		pushc 4
		pushcl SND_MSG
		regrxn
		
// register reaction to move to a different node
		pusht location
		aid
		pushn abc
		pushc 3
		pushcl MOVE
		regrxn
WAIT		wait
		
RXN_FIRED	remove			// remove the tuple
		pushloc force_uart_x force_uart_y
		rout			// send tuple to base station
		endrxn

SND_MSG		remove
		pop
		pop
		pushn mbm
		pushc 4			// <"mbm", AgentID, String:name, String:msg>
		getvar 1
		rout			// send to leader	
		pushc 26
		putled			// toggle green when message is sent to leader
		endrxn

MOVE		pushc 28	
		putled
		remove			// remove the tuple
		pop			// pop off number of fields
		pop			// pop off "mov"
		pop			// pop off agent id
		
		aid
		pushn msc
		pushc 2
		pushloc	force_uart_x force_uart_y
		rout			// tell current base station to kill GUI
		
		pushloc 2 1			// copy destination location
		aid
		pushn upd
		pushc 3			// tuple: <"upd", AgentID, new location>
		getvar 1
		rout			// send update location message to leader
		
		smove			// strong move to destination
		
		getvar	0
		aid
		pushn	msc
		pushc	3
		pushloc	force_uart_x force_uart_y
		rout			// send message to base station to create GUI
		endrxn