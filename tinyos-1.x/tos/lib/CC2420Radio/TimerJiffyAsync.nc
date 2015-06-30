//$Id: TimerJiffyAsync.nc,v 1.1 2004/05/15 00:25:16 jpolastre Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

interface TimerJiffyAsync
{
  async command result_t setOneShot( uint32_t jiffy );

  async command result_t stop();

  async command bool isSet();

  async event result_t fired();
}

