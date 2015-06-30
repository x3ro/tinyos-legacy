//$Id: TimerJiffy.nc,v 1.1 2004/08/04 15:50:42 jdprabhu Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

interface TimerJiffy
{
  command result_t setPeriodic( int32_t jiffy );
  command result_t setOneShot( int32_t jiffy );

  command result_t stop();

  command bool isSet();
  command bool isPeriodic();
  command bool isOneShot();
  command int32_t getPeriod();

  event result_t fired();
}

