		pushc 0			// store the group member information on the heap
		setvar 0		// heap[0] = initial number of members (0)				


// register a reaction sensitive to join messages
		pusht location
		pushn jng
		pushc 2
		pushc RXN_GROUP_JOIN
		regrxn
	
// register a reaction sensitive to member broadcast messages		
		pusht value
		pushn mbm
		pushc 2			// template = <"mbm", value>
		pushc RXN_GROUP_SEND
		regrxn			// register a reaction for member broadcast messages
		wait

// The group send reaction
// Assumes heap[0] = number of agents and heap[1...n] are the agent's addresses
RXN_GROUP_SEND	remove
		pop
		pop
		esetvar 19
		pushc 0
RGS_LOOP	inc
		copy
		getvar 0
		cgt			// check whether the counter is > number of members
		rjumpc DONE
		copy
		getvars			// get the neighbor's address
		egetvar 19		
		swap
		pushn lbm
		swap
		pushc 2
		swap			// tuple = <"lbm", 31>
		rout
		pushc RGS_LOOP
		jumps			// go back to STG_LOOP		
DONE		pop			// pop the counter
		endrxn			// end the reaction

// The group join reaction
// Assumes heap[0] = number of agents and heap[1...n] are the agent's addresses
RXN_GROUP_JOIN	remove
		pop			// pop number of fields
		pop			// pop the string "jng"
		getvar 0
		inc
		copy
		setvar 0		// heap[0]++
		setvars			// save the location of the member on the heap
		endrxn
		