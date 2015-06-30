		pushc 4			// store the group member information on the heap
		setvar 0		// heap[0] = number of members (4)		
		pushloc 2 1
		pushloc 3 1
		pushloc 4 1		
		pushloc 5 1
		setvar 1
		setvar 2
		setvar 3
		setvar 4
		
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
		
		
