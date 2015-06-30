configuration TestIeee802154Phy
{

}

implementation
{
	components Main, TestIeee802154PhyM, Ieee802154PhyC, ConsoleC;

	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> Ieee802154PhyC.StdControl;
	Main.StdControl -> TestIeee802154PhyM.StdControl;
	
	TestIeee802154PhyM.ConsoleOut -> ConsoleC.ConsoleOut;

	TestIeee802154PhyM.IeeePhyPibAttribute -> Ieee802154PhyC.IeeePhyPibAttribute;
	TestIeee802154PhyM.IeeePhySdu -> Ieee802154PhyC.IeeePhySdu;

	// PLME
	TestIeee802154PhyM.PlmeRequestConfirmCca -> Ieee802154PhyC.PlmeRequestConfirmCca;
	TestIeee802154PhyM.PlmeCcaRequestConfirm -> Ieee802154PhyC.PlmeCcaRequestConfirm;

	TestIeee802154PhyM.PlmeRequestConfirmEd -> Ieee802154PhyC.PlmeRequestConfirmEd;
	TestIeee802154PhyM.PlmeEdRequestConfirm -> Ieee802154PhyC.PlmeEdRequestConfirm;

	TestIeee802154PhyM.PlmeRequestConfirmGet -> Ieee802154PhyC.PlmeRequestConfirmGet;
	TestIeee802154PhyM.PlmeGetRequestConfirm -> Ieee802154PhyC.PlmeGetRequestConfirm;

	TestIeee802154PhyM.PlmeRequestConfirmSet -> Ieee802154PhyC.PlmeRequestConfirmSet;
	TestIeee802154PhyM.PlmeSetRequestConfirm -> Ieee802154PhyC.PlmeSetRequestConfirm;

	TestIeee802154PhyM.PlmeRequestConfirmSetTrxState -> Ieee802154PhyC.PlmeRequestConfirmSetTrxState;
	TestIeee802154PhyM.PlmeSetTrxStateRequestConfirm -> Ieee802154PhyC.PlmeSetTrxStateRequestConfirm;
	
	// PD
	TestIeee802154PhyM.PdRequestConfirmData -> Ieee802154PhyC.PdRequestConfirmData;
	TestIeee802154PhyM.PdDataRequestConfirm -> Ieee802154PhyC.PdDataRequestConfirm;

	TestIeee802154PhyM.PdIndicationData -> Ieee802154PhyC.PdIndicationData;
	TestIeee802154PhyM.PdDataIndication -> Ieee802154PhyC.PdDataIndication;
}
