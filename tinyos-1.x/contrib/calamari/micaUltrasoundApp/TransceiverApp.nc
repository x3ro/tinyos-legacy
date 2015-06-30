/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/30/03
 */

includes Omnisound;

configuration TransceiverApp {}

implementation {
	components Main, TransceiverAppM, TransmitterC, ReceiverC, TimerM, ClockC, HPLPowerManagementM, LedsC, GenericComm as Comm;
	Main.StdControl -> TransceiverAppM;
	Main.StdControl -> TimerM;
	TimerM.Clock -> ClockC;
	TimerM.Leds -> LedsC;
	TimerM.PowerManagement -> HPLPowerManagementM;
	TransceiverAppM.PulseMsg -> Comm.ReceiveMsg[AM_PULSE];
	TransceiverAppM.Timer -> TimerM.Timer[unique("Timer")];
	TransceiverAppM.TransmitterControl -> TransmitterC;
	TransceiverAppM.Transmitter -> TransmitterC;
 	TransceiverAppM.ReceiverControl -> ReceiverC.StdControl;
	TransceiverAppM.Receiver -> ReceiverC; 
	TransceiverAppM.TimestampSend -> Comm.SendMsg[AM_TOF];
	TransceiverAppM.Leds -> LedsC;
}
