includes TSTestApp;
includes Routing;
includes Neighborhood;

includes SpanTree;
includes ERBcast;
includes Config;
includes Routing;


configuration TSTestAppC
{
}
implementation
{
  components Main
           , SystemC
           , RouteInterpretC
           , SpanTreeC
           , TSTestAppM
           , TinySecC
	   ;

  Main.StdControl -> SystemC;
  
  SystemC.Init[30] -> RouteInterpretC;

  TSTestAppM.TinySecMode -> TinySecC.TinySecMode;
}

