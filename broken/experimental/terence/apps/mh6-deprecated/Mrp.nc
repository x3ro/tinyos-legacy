configuration Mrp {
	provides {
		interface RouteHeader;
		interface RouteState;
	}
	uses {
		interface CommNotifier;
	}
}

implementation {
	components MrpM, Main, RouteHelper, RandomLFSR, ChildrenCache, TimerWrapper, LedsC, VirtualComm;
	Main.StdControl -> MrpM.StdControl;
	RouteHeader = MrpM.RouteHeader;
	CommNotifier = MrpM.CommNotifier;
	RouteState = MrpM.RouteState;
	MrpM.RouteHelp -> RouteHelper.RouteHelp;
	MrpM.Timer -> TimerWrapper.Timer[unique("Timer")];
	MrpM.OffsetTimer -> TimerWrapper.Timer[unique("Timer")];
	MrpM.Children -> ChildrenCache.Children;
	MrpM.Random -> RandomLFSR.Random;
	MrpM.Leds -> LedsC.Leds;

}
