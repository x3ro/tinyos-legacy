//-------------------------------------------------------------------------------------------------
// Group Communication Leader
//
// Heap Structure:
//   [0] = number of members
//   [1..n] = member locations
//
// Number of reactions: 2
//   (1) Distributes a group message.  
//       Tuple format: <"mbm", value>
//   (2) Adds a member to the group.
//       Tuple format: <"jng", location>
//-------------------------------------------------------------------------------------------------
		pushc 0			// store the group member information on the heap
		setvar 0		// heap[0] = initial number of members (0)				


// register a reaction sensitive to join messages
		pusht location
		pusht agentid
		pushn jng
		pushc 3
		pushcl RXN_GROUP_JOIN
		regrxn
	
// register a reaction sensitive to member broadcast messages		
		pusht string
		pusht string
		pusht agentid
		pushn mbm
		pushc 4			// template = <"mbm", agentID, string, string>
		pushc RXN_GROUP_SEND
		regrxn			// register a reaction for member broadcast messages
		
// register a reaction sensitive to member update messages
		pusht location
		pusht agentid
		pushn upd
		pushc 3
		pushcl RXN_UPDATE_LOC
		regrxn
WAIT		wait

// The group send reaction sensitive to <"mbm", string, string>
// Assumes heap[0] = number of agents and heap[1...n] are the agent's addresses
RXN_GROUP_SEND	remove
		pop
		pop
		pop
		esetvar 19		// heap[19] = name
		esetvar 18		// heap[18] = message
		pushc 28
		putled			// toggle yellow
		pushc 0
		esetvar 17
RGS_LOOP	egetvar 17
		inc
		copy			// Stack:  cntr, cntr
		
		esetvar	17		// heap[17] = cntr
		
		getvar 0		// Stack:  # of members, cntr
		cgt			// check whether the counter is > number of members
		pushcl DONE
		jumpc	
				
		egetvar 18		// message				
		egetvar 19		// member's name

		egetvar 17		
		pushc 2
		mul					
		dec			// 2*idx - 1
		getvars			// each member's agent ID

		//copy
		//pushn rcv
		//pushc 2
		//pushloc uart_x uart_y
		//rout	

		pushn lbm
		pushc 4			// tuple = <"lbm", member ID, name, message>
		
		egetvar 17
		pushc 2
		mul			// 2*idx		
		getvars			// get the member's address	
		//pushloc uart_x uart_y
		//copy
		//pushn rcv
		//pushc 2
		//pushloc uart_x uart_y
		//rout	
	
		rout
		pushc RGS_LOOP
		jumps			// go back to STG_LOOP		
DONE		pushc 25
		putled			// toggle red
		//pop			// pop the counter	
		endrxn			// end the reaction

// The group join reaction sensitive to <"jng", location>
// Assumes heap[0] = number of agents and heap[1...n] are the agent's addresses
RXN_GROUP_JOIN	remove
		pop			// pop number of fields
		pop			// pop the string "jng"
		getvar 0
		inc
		copy
		setvar 0		// heap[0]++
		pushc 2
		mul
		dec
		setvars			// heap[index*2-1] = agent id
		getvar 0
		pushc 2
		mul
		setvars			// heap[index*2] = location
		pushc 28
		putled			// toggle yellow when member joins group
		
		//getvar  0
		//pushc	2
		//mul
		//getvars
		//pushn mem		// tell BS that a member has joined
		//pushc 2
		//pushloc uart_x uart_y
		//rout
		
		endrxn
		
RXN_UPDATE_LOC  remove
		pushc 25
		putled			// toggle red LED when member moves
		pop			// pop number of fields
		pop			// pop the string "upd"
		findMatch		// find the index of the agent id on the heap
		inc			// the location is in the next index position
		setvars			// save the new location
		endrxn