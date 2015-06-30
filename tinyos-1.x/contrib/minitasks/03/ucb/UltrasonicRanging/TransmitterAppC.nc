/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/27/03
 */

includes TransmitterApp;
includes Omnisound;

configuration TransmitterAppC{}

implementation {
	components Main, TransmitterServiceC, ReceiverC, SystemC, GenericComm as Comm, TransmitterAppM;
	
	Main.StdControl -> SystemC;
	SystemC.Init[20] -> ReceiverC;
	SystemC.Service[20] -> TransmitterServiceC;
	TransmitterAppM.UltrasonicRangingReceiver -> ReceiverC;
	TransmitterAppM.ReportRangingEst->Comm.SendMsg[AM_TOF]; // Report over RF
}
