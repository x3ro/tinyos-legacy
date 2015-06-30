includes DefineCC1000;

configuration RFPowerC
{
  provides interface StdControl;
}
implementation
{
  components RFPowerM
#if defined(RADIO_CC1000)
           , CC1000ControlM
#endif
	   ;

  StdControl = RFPowerM;

#if defined(RADIO_CC1000)
  RFPowerM.CC1000Control -> CC1000ControlM;
#endif
}

