configuration CalamariC {
}

implementation { 
  components  
    Main,
    LocalizationC,
    RssiLocalizationC,
    RegistryC;

  Main.StdControl -> LocalizationC;
  Main.StdControl -> RssiLocalizationC;
  Main.StdControl -> RegistryC;


}
