
configuration TestMain {
}
implementation {
	components Main,
	           TestMainM,
	           Freescale802154C,
	           LedsC,
	           ConsoleC;

	Freescale802154C.ConsoleOut -> ConsoleC.ConsoleOut;
	Freescale802154C.Leds -> LedsC;
	
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> TestMainM.StdControl;
 
 	TestMainM.Control -> Freescale802154C;
 	TestMainM.Leds -> LedsC;
 	
	TestMainM.IeeePibAttribute -> Freescale802154C;
	TestMainM.IeeePanDescriptor -> Freescale802154C;
	TestMainM.IeeeSdu -> Freescale802154C;
	
	// MCPS
	TestMainM.McpsIndicationData ->Freescale802154C.McpsIndicationData;
	TestMainM.McpsRequestConfirmData -> Freescale802154C.McpsRequestConfirmData;
	
	TestMainM.McpsDataIndication ->Freescale802154C.McpsDataIndication;
	TestMainM.McpsDataRequestConfirm -> Freescale802154C.McpsDataRequestConfirm;
	
	// MLME
	TestMainM.MlmeIndicationResponseAssociate -> Freescale802154C.MlmeIndicationResponseAssociate;
	TestMainM.MlmeRequestConfirmAssociate -> Freescale802154C.MlmeRequestConfirmAssociate;
	TestMainM.MlmeIndicationGts -> Freescale802154C.MlmeIndicationGts;
	TestMainM.MlmeRequestConfirmGts -> Freescale802154C.MlmeRequestConfirmGts;
	TestMainM.MlmeRequestConfirmScan -> Freescale802154C.MlmeRequestConfirmScan;
	TestMainM.MlmeRequestConfirmSet -> Freescale802154C.MlmeRequestConfirmSet;
	TestMainM.MlmeRequestConfirmStart -> Freescale802154C.MlmeRequestConfirmStart;
	TestMainM.MlmeIndicationSyncLoss -> Freescale802154C.MlmeIndicationSyncLoss;

	TestMainM.MlmeAssociateIndicationResponse -> Freescale802154C.MlmeAssociateIndicationResponse;
	TestMainM.MlmeAssociateRequestConfirm -> Freescale802154C.MlmeAssociateRequestConfirm;
	TestMainM.MlmeGtsIndication -> Freescale802154C.MlmeGtsIndication;
	TestMainM.MlmeGtsRequestConfirm -> Freescale802154C.MlmeGtsRequestConfirm;
	TestMainM.MlmeScanRequestConfirm -> Freescale802154C.MlmeScanRequestConfirm;	
	TestMainM.MlmeSetRequestConfirm -> Freescale802154C.MlmeSetRequestConfirm;
	TestMainM.MlmeStartRequestConfirm -> Freescale802154C.MlmeStartRequestConfirm;
	TestMainM.ConsoleOut -> ConsoleC.ConsoleOut;
	TestMainM.ConsoleIn -> ConsoleC.ConsoleIn;
  
}
