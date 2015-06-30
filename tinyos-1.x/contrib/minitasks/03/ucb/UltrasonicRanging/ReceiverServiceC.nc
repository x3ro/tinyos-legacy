/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/27/03
 */

includes Omnisound;

configuration ReceiverServiceC{
	provides interface StdControl;
}

implementation {
	components ReceiverAppM, ReceiverC, LedsC, GenericComm as Comm;
	StdControl = ReceiverAppM;
	StdControl = ReceiverC;
	ReceiverAppM.Receiver -> ReceiverC;
	ReceiverAppM.TimestampSend -> Comm.SendMsg[AM_TOF];
	ReceiverAppM.Leds -> LedsC;
}

