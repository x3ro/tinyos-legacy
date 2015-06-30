//$Id: Main.nc,v 1.3 2005/08/01 18:13:46 jwhui Exp $

module Main
{
  provides interface StdControl as AppControl;
  uses interface StdControl;
}
implementation
{
  command result_t AppControl.init() { return call StdControl.init(); }
  command result_t AppControl.start() { return call StdControl.start(); }
  command result_t AppControl.stop() { return call StdControl.stop(); }
}

