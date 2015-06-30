		pushc 0
		setvar 0
BEGIN		pushc 26
		putled 		   // toggle green LED						
		getvar 0
		copy
		inc
		setvar 0
		pushc accelx
		sense		   // sense x axis of accelerometer
		pushc 2
		pushloc uart_x uart_y
		rout         // remote out tuple containing temperature reading to laptop
		pushc 1
		sleep
		rjump BEGIN
