includes Localization;
includes LocalizationConfig;
includes LocalizationApp;
includes Routing;
includes Neighborhood;
includes Config;

includes Omnisound;

configuration LocalizationAppC
{
}
implementation
{
  components Main
           , SystemC
       	   , CalamariC
	   ;

  Main.StdControl -> SystemC;
        SystemC.Service[50] -> CalamariC;
}

