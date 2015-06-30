		pushcl 100
BEGIN		pushc 25
		putled		// toggle green LED		
		pushc 0
		getClosestAgent
		pushc 25
		putled		// toggle green LED		
		rjumpc SUCCESS
		rjump CONTINUE
SUCCESS		pop
		pop
CONTINUE	dec
		copy
		pushc 0
		cneq
		pushc BEGIN
		jumpc 
		halt
