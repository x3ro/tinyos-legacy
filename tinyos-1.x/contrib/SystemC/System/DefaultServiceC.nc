
configuration DefaultServiceC
{
  provides interface StdControl;
}
implementation
{
  components DefaultServiceM
           , TimedLedsC
	   ;
  
  StdControl = DefaultServiceM;

  DefaultServiceM.TimedLeds -> TimedLedsC;
}

