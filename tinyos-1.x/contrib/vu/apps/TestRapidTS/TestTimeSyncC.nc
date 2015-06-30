/*
 * Author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: Dec04
 */

configuration TestTimeSyncC {
}

implementation {
	components  Main, TimerC, GenericComm, TimeSyncC, TimeSyncDebuggerC; //SimpleXnpC,
	        //RemoteControlC, LedCommandsC, ResetCommandsC;//, VoltageCommandsC, RadioCommandsC;

	Main.StdControl -> TimerC;
	Main.StdControl -> GenericComm;
	Main.StdControl -> TimeSyncC;
	Main.StdControl -> TimeSyncDebuggerC;
	//SimpleXnpC.Shutdown -> TimeSyncC.StdControl;

}
