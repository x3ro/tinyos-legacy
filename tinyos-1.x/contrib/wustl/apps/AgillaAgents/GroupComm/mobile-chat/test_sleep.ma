BEGIN		pusht	STRING
		pushc	1
		
		pushc	RXN
		regrxn
		
		pushcl	480
		sleep
		
		pushc	26
		putled
		halt
		
RXN		remove
		pushc	25
		putled
		endrxn
		