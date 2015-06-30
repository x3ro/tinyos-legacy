includes macConstants;

configuration TestFreescale802154
{

}

implementation
{
	components Main,
	           ScanM,
	           SynchronizeM,
	           PibAttributeServiceM,
	           Test802154M,
	           Freescale802154C,
	           ConsoleDebugM,
	           ConsoleC;
	
	ConsoleDebugM.ConsoleOut -> ConsoleC.ConsoleOut;
	ScanM.Debug -> ConsoleDebugM.Debug;
	SynchronizeM.Debug -> ConsoleDebugM.Debug;
	PibAttributeServiceM.Debug -> ConsoleDebugM.Debug;
	Test802154M.Debug -> ConsoleDebugM.Debug;
	Freescale802154C.Debug -> ConsoleDebugM.Debug;
	
	
	Main.StdControl -> Freescale802154C.StdControl;
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> Test802154M.StdControl;
	Main.StdControl -> SynchronizeM.StdControl;
 	
	SynchronizeM.IeeePibAttribute -> Freescale802154C;
	SynchronizeM.IeeePanDescriptor -> Freescale802154C;
	SynchronizeM.IeeeAddress -> Freescale802154C;
	
	ScanM.IeeePanDescriptor -> Freescale802154C;
	ScanM.IeeeAddress -> Freescale802154C;
	
	PibAttributeServiceM.IeeePibAttribute -> Freescale802154C;

	SynchronizeM.PibAttributeService -> PibAttributeServiceM.PibAttributeService;
	Test802154M.Synchronize -> SynchronizeM.Synchronize;
	Test802154M.BeaconScan -> ScanM.BeaconScan;
	
	// MLME
	ScanM.MlmeRequestConfirmScan -> Freescale802154C.MlmeRequestConfirmScan;
	PibAttributeServiceM.MlmeRequestConfirmSet -> Freescale802154C.MlmeRequestConfirmSet;
	SynchronizeM.MlmeIndicationSyncLoss -> Freescale802154C.MlmeIndicationSyncLoss;	
	SynchronizeM.MlmeRequestSync -> Freescale802154C.MlmeRequestSync;
	SynchronizeM.MlmeIndicationBeaconNotify -> Freescale802154C.MlmeIndicationBeaconNotify;

	ScanM.MlmeScanRequestConfirm -> Freescale802154C.MlmeScanRequestConfirm;		
	PibAttributeServiceM.MlmeSetRequestConfirm -> Freescale802154C.MlmeSetRequestConfirm;
	SynchronizeM.MlmeBeaconNotifyIndication -> Freescale802154C.MlmeBeaconNotifyIndication;
	SynchronizeM.MlmeSyncLossIndication -> Freescale802154C.MlmeSyncLossIndication;
	SynchronizeM.MlmeSyncRequest -> Freescale802154C.MlmeSyncRequest;

	// console IO
	Test802154M.ConsoleOut -> ConsoleC.ConsoleOut;
	Test802154M.ConsoleIn -> ConsoleC.ConsoleIn;
}
