

/* 
 *
 * Orriginall taken from AttrTemp* code. - Martin Lukac
 * 
 *
 */
// component to expose Stargate button sensor reading as an attribute

configuration AttrSButton
{
	provides 
	{
		interface StdControl;
		interface SButton;
		//		interface ADC as SButtonADC;
		//		interface StdControl;
	}
}
implementation
{
	components SButtonM, AttrSButtonM, Attr;

	StdControl = AttrSButtonM;
	AttrSButtonM.AttrRegister -> Attr.Attr[unique("Attr")];
	SButton = SButtonM;
	AttrSButtonM.SButton -> SButtonM;
	AttrSButtonM.SButtonCtl -> SButtonM.StdControl;
	/*
	  components SButton, AttrSButtonM, Attr;
	  
	  SButtonADC = SButton;
	  StdControl = SButton;
	  StdControl = AttrSButtonM;
	  AttrSButtonM.AttrRegister -> Attr.Attr[unique("Attr")];
	  AttrSButtonM.ADC -> SButton.SButtonADC;
	  AttrSButtonM.SubControl -> SButton.StdControl;
	*/
}
