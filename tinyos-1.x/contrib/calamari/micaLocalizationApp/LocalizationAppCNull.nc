includes Localization;
includes LocalizationConfig;
includes LocalizationApp;
includes Routing;
includes Neighborhood;
includes Config;

includes Omnisound;

configuration LocalizationAppCNull
{
}
implementation
{
  components Main
           , SystemC
   	   , CalamariCNull
	   ;

  Main.StdControl -> SystemC;
  SystemC.Service[50] -> CalamariCNull;
}

