includes macConstants;
includes mcuToRadioPorts;

configuration Test802154MacRadioOpLayer
{

}
implementation
{
	components Main,
	           AsyncAlarmC,
	           LocalTimeM,
	           Test802154MacRadioOpLayerM,
	           mc13192Ieee802154RadioC,
	           Ieee802154PhyC,
	           HPLSPIM as mcuSPI,
	           RadioOperationsC,
	           FrameControlC,
	           PrimitiveHandlerC,
	           MacPibDatabaseM,
	           FIFOQueueM,
	           SimpleBufferManM,
	           RandomLFSR,
	           LedsC,
	           RTSchedulerM,
	           BeaconTrackerM,
	           SuperframeM,
	           MlmeBeaconNotifyIndicationM,
	           MlmeSyncRequestM,
	           ConsoleDebugM,
	           ConsoleC;

	ConsoleDebugM.ConsoleOut -> ConsoleC.ConsoleOut;
	RadioOperationsC.Debug -> ConsoleDebugM.Debug;
	PrimitiveHandlerC.Debug -> ConsoleDebugM.Debug;
	FrameControlC.Debug -> ConsoleDebugM.Debug;
	Ieee802154PhyC.Debug -> ConsoleDebugM.Debug;
	FIFOQueueM.Debug -> ConsoleDebugM.Debug;
	SimpleBufferManM.Debug -> ConsoleDebugM.Debug;
	Test802154MacRadioOpLayerM.Debug -> ConsoleDebugM.Debug;
	RTSchedulerM.Debug -> ConsoleDebugM.Debug;
	AsyncAlarmC.Debug -> ConsoleDebugM.Debug;
	mc13192Ieee802154RadioC.Debug -> ConsoleDebugM.Debug;
	BeaconTrackerM.Debug -> ConsoleDebugM.Debug;
	SuperframeM.Debug -> ConsoleDebugM.Debug;
	
	MacPibDatabaseM.Random -> RandomLFSR.Random;
	//RadioOperationsC.Random -> RandomLFSR.Random;
	
	// Connect radio.
	mc13192Ieee802154RadioC.SPI -> mcuSPI.SPI;
	mc13192Ieee802154RadioC.Debug -> ConsoleDebugM.Debug;
	mc13192Ieee802154RadioC.ConsoleOut -> ConsoleC.ConsoleOut;
	mc13192Ieee802154RadioC.LocalTime -> LocalTimeM.LocalTime;
	
	// Wire the phy layer externally.
	Ieee802154PhyC.RadioControl -> mc13192Ieee802154RadioC.Control;
	Ieee802154PhyC.RadioSend -> mc13192Ieee802154RadioC.Send;
	Ieee802154PhyC.RadioRecv -> mc13192Ieee802154RadioC.Recv;
	Ieee802154PhyC.RadioCCA -> mc13192Ieee802154RadioC.CCA;
	
	// Connect timers.
	//RadioOperationsC.CsmaAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	RadioOperationsC.CcaAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	RadioOperationsC.EdAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	RadioOperationsC.RxEnableAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	RadioOperationsC.AckAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	BeaconTrackerM.TrackAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	RadioOperationsC.LocalTime -> LocalTimeM.LocalTime;
	SuperframeM.LocalTime -> LocalTimeM.LocalTime;
	
	Main.StdControl -> mcuSPI.StdControl;
	Main.StdControl -> mc13192Ieee802154RadioC.StdControl;
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> AsyncAlarmC.StdControl;
	Main.StdControl -> SimpleBufferManM.StdControl;
	Main.StdControl -> RTSchedulerM.StdControl;
	Main.StdControl -> Ieee802154PhyC.StdControl;

	Main.StdControl -> MacPibDatabaseM.StdControl;
	Main.StdControl -> RadioOperationsC.StdControl;
	Main.StdControl -> Test802154MacRadioOpLayerM.StdControl;

 	mcuSPI.Leds -> LedsC;
 
	// Wire the mac layer to the phy layer.
	RadioOperationsC.IeeePhyPibAttribute -> Ieee802154PhyC.IeeePhyPibAttribute;
	RadioOperationsC.IeeePhySdu -> Ieee802154PhyC.IeeePhySdu;
	
	RadioOperationsC.PlmeCcaRequestConfirm -> Ieee802154PhyC.PlmeCcaRequestConfirm;
	RadioOperationsC.PlmeEdRequestConfirm -> Ieee802154PhyC.PlmeEdRequestConfirm;
	RadioOperationsC.PlmeGetRequestConfirm -> Ieee802154PhyC.PlmeGetRequestConfirm;
	RadioOperationsC.PlmeSetRequestConfirm -> Ieee802154PhyC.PlmeSetRequestConfirm;
	RadioOperationsC.PlmeSetTrxStateRequestConfirm -> Ieee802154PhyC.PlmeSetTrxStateRequestConfirm;
	RadioOperationsC.PlmeRequestConfirmCca -> Ieee802154PhyC.PlmeRequestConfirmCca;
	RadioOperationsC.PlmeRequestConfirmEd -> Ieee802154PhyC.PlmeRequestConfirmEd;
	RadioOperationsC.PlmeRequestConfirmGet -> Ieee802154PhyC.PlmeRequestConfirmGet;
	RadioOperationsC.PlmeRequestConfirmSet -> Ieee802154PhyC.PlmeRequestConfirmSet;
	RadioOperationsC.PlmeRequestConfirmSetTrxState -> Ieee802154PhyC.PlmeRequestConfirmSetTrxState;
	RadioOperationsC.PdDataRequestConfirm -> Ieee802154PhyC.PdDataRequestConfirm;
	RadioOperationsC.PdDataIndication -> Ieee802154PhyC.PdDataIndication;
	RadioOperationsC.PdRequestConfirmData -> Ieee802154PhyC.PdRequestConfirmData;
	RadioOperationsC.PdIndicationData -> Ieee802154PhyC.PdIndicationData;
	
	// Inter-mac wiring
	
	FrameControlC.RadioChannel -> RadioOperationsC.RadioChannel;
	FrameControlC.Ed -> RadioOperationsC.Ed;
	FrameControlC.BeaconFrame -> RadioOperationsC.BeaconFrame;
	FrameControlC.CoordRealignFrame -> RadioOperationsC.CoordRealignFrame;
	FrameControlC.RxEnable -> RadioOperationsC.RxEnable;
	FrameControlC.RadioAccess -> RadioOperationsC.RadioAccess;
	PrimitiveHandlerC.ScanService -> FrameControlC.ScanService;
	
	BeaconTrackerM.RadioAccess -> RadioOperationsC.RadioAccess;
	BeaconTrackerM.RadioChannel -> RadioOperationsC.RadioChannel;
	BeaconTrackerM.RxEnable -> RadioOperationsC.RxEnable;
	BeaconTrackerM.BeaconFrame -> RadioOperationsC.BeaconFrame;
	BeaconTrackerM.Superframe -> SuperframeM.Superframe;
	
	// App wiring.
	Test802154MacRadioOpLayerM.RadioChannel -> RadioOperationsC.RadioChannel;		
	Test802154MacRadioOpLayerM.FrameTx -> RadioOperationsC.FrameTx;
	Test802154MacRadioOpLayerM.RadioIdleControl -> RadioOperationsC.RadioIdleControl;
	
	Test802154MacRadioOpLayerM.MlmeRequestConfirmScan -> PrimitiveHandlerC.MlmeRequestConfirmScan;
	Test802154MacRadioOpLayerM.MlmeScanRequestConfirm -> PrimitiveHandlerC.MlmeScanRequestConfirm;
	Test802154MacRadioOpLayerM.IeeePanDescriptor -> PrimitiveHandlerC.IeeePanDescriptor;
	Test802154MacRadioOpLayerM.IeeeAddress -> PrimitiveHandlerC.IeeeAddress;
	
	Test802154MacRadioOpLayerM.MlmeRequestSync ->  BeaconTrackerM.MlmeRequestSync;
	Test802154MacRadioOpLayerM.MlmeSyncRequest -> MlmeSyncRequestM.MlmeSyncRequest;
	Test802154MacRadioOpLayerM.MlmeIndicationBeaconNotify -> BeaconTrackerM.MlmeIndicationBeaconNotify;
	Test802154MacRadioOpLayerM.MlmeBeaconNotifyIndication -> MlmeBeaconNotifyIndicationM.MlmeBeaconNotifyIndication;

	Test802154MacRadioOpLayerM.ConsoleIn -> ConsoleC.ConsoleIn;
	Test802154MacRadioOpLayerM.ConsoleOut -> ConsoleC.ConsoleOut;
	
	// Wire the queue module.
	SimpleBufferManM.Queue -> FIFOQueueM.FIFOQueue;
	RTSchedulerM.Queue -> FIFOQueueM.FIFOQueue;
	
	// Wire the buffer manager.
	Ieee802154PhyC.BufferMng -> SimpleBufferManM.BufferMng;
	PrimitiveHandlerC.BufferMng -> SimpleBufferManM.BufferMng;
	BeaconTrackerM.BufferMng -> SimpleBufferManM.BufferMng;
	MlmeSyncRequestM.BufferMng -> SimpleBufferManM.BufferMng;
	MlmeBeaconNotifyIndicationM -> SimpleBufferManM.BufferMng;
	
	// Task sched wiring
	RTSchedulerM.Timer -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	RTSchedulerM.Events -> mc13192Ieee802154RadioC.Events;
	RadioOperationsC.RTScheduler -> RTSchedulerM.RTScheduler;
	Ieee802154PhyC.RTScheduler -> RTSchedulerM.RTScheduler;
}
