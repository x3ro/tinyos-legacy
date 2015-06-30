//$Id: TimerJiffyAsync.nc,v 1.1.1.1 2007/11/05 19:09:07 jpolastre Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

interface TimerJiffyAsync
{
  async command result_t setOneShot( uint32_t jiffy );

  async command result_t stop();

  async command bool isSet();

  async event result_t fired();
}

