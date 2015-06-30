
includes ResetSystem;

configuration ResetSystemC
{
  provides interface StdControl;
}
implementation
{
  components ResetSystemM
           , ResetC
	   , SystemGenericCommC as GenericComm
	   ;
  
  StdControl = ResetSystemM;

  ResetSystemM.Reset -> ResetC;
  ResetSystemM.ResetMsg -> GenericComm.ReceiveMsg[AM_RESET];
}

