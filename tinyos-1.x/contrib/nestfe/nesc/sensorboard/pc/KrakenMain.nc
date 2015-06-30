// $Id: KrakenMain.nc,v 1.1 2005/07/26 21:48:32 kaminw Exp $

configuration KrakenMain
{
  uses interface StdControl as PreInitControl;
  uses interface StdControl as AppControl;
}
implementation
{
  components Main;

  //Anything that gets init by KrakenMain really gets init by Main
  PreInitControl = Main.StdControl;
  AppControl = Main.StdControl;


}

