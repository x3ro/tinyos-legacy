configuration TestLocalizationC
{
}
implementation
{
  components  
    Main,
    //RssiLocalizationC,
    KrakenC;

  //  Main.StdControl -> RssiLocalizationC;
  Main.StdControl -> KrakenC;
}

