//$Id: SplitInit.nc,v 1.1 2005/07/22 04:38:46 jaein Exp $

interface SplitInit
{
  command result_t init();
  event void initDone();
}

