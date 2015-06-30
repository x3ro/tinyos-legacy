configuration RssiLocalizationC {
  provides interface StdControl;
}

implementation { 
  components  
    RssiLocalizationM,
    RssiLocationHoodC,
    RssiLocationHoodManagerC,
    RegistryC;

  StdControl = RssiLocalizationM;
  StdControl = RssiLocationHoodC;
  StdControl = RssiLocationHoodManagerC;

  RssiLocalizationM.RssiLocation -> RegistryC.RssiLocation;
  RssiLocalizationM.RssiLocationRefl -> RssiLocationHoodC.RssiLocationRefl;


}
