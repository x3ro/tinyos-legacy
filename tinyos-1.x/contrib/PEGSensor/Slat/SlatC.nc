includes MagCenter;
includes Routing;
includes Neighborhood;
includes Config;

configuration SlatC
{
}
implementation
{
  components Main
           , SystemC
           , MagReadingC
	   ;

  Main.StdControl -> SystemC;
  SystemC.Service[10] -> MagReadingC;
}

