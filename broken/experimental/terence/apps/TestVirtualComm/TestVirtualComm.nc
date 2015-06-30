
configuration TestVirtualComm {
	
}

implementation {
	components Main, TestVirtualCommM, VirtualComm, TimerWrapper, LedsC, RandomLFSR, BitArrayC;
	Main.StdControl -> TestVirtualCommM.StdControl;
	TestVirtualCommM.VCSend1 -> VirtualComm.VCSend[1];
	TestVirtualCommM.Timer1 -> TimerWrapper.Timer[unique("Timer")];
	TestVirtualCommM.Random -> RandomLFSR.Random;
	TestVirtualCommM.VCSend2 -> VirtualComm.VCSend[2];
	TestVirtualCommM.Timer2 -> TimerWrapper.Timer[unique("Timer")];
	TestVirtualCommM.VCSend3 -> VirtualComm.VCSend[3];
	TestVirtualCommM.Timer3 -> TimerWrapper.Timer[unique("Timer")];
	/*
	TestVirtualCommM.VCSend4 -> VirtualComm.VCSend[4];
	TestVirtualCommM.Timer4 -> TimerWrapper.Timer[unique("Timer")];
	TestVirtualCommM.VCSend5 -> VirtualComm.VCSend[5];
	TestVirtualCommM.Timer5 -> TimerWrapper.Timer[unique("Timer")];
	TestVirtualCommM.VCSend6 -> VirtualComm.VCSend[6];
	TestVirtualCommM.Timer6 -> TimerWrapper.Timer[unique("Timer")];
	TestVirtualCommM.VCSend7 -> VirtualComm.VCSend[7];
	TestVirtualCommM.Timer7 -> TimerWrapper.Timer[unique("Timer")];
	TestVirtualCommM.VCSend8 -> VirtualComm.VCSend[8];
	TestVirtualCommM.Timer8 -> TimerWrapper.Timer[unique("Timer")];
	TestVirtualCommM.VCSend9 -> VirtualComm.VCSend[9];
	TestVirtualCommM.Timer9 -> TimerWrapper.Timer[unique("Timer")];
	TestVirtualCommM.VCSend10 -> VirtualComm.VCSend[10];
	TestVirtualCommM.Timer10 -> TimerWrapper.Timer[unique("Timer")];
	*/
	TestVirtualCommM.Leds -> LedsC;
	TestVirtualCommM.BitArray -> BitArrayC.BitArray;

}
