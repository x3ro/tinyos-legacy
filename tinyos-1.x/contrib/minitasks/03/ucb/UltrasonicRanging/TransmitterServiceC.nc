/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/27/03
 */

configuration TransmitterServiceC{
	provides interface StdControl;
}

implementation {
	components TransmitterAppM, TransmitterC, TimerM, LedsC;
	StdControl = TransmitterAppM;
	StdControl = TransmitterC;
	TransmitterAppM.Transmitter -> TransmitterC;
	TransmitterAppM.Timer -> TimerM.Timer[unique("Timer")];
	TransmitterAppM.Leds -> LedsC;
}

