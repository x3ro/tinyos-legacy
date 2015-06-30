		pushc 50
BEGIN		pushc 25
		putled		// toggle green LED		
		pushc 0
		getAgentLocation
		pushc 25
		putled		// toggle green LED
		rjumpc FOUND
		rjump CONTINUE
FOUND		pop		// pop the location off the stack
CONTINUE	dec
		copy
		pushc 0
		cneq
		pushc BEGIN
		jumpc
