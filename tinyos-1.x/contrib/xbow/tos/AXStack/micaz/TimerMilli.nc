//$Id: TimerMilli.nc,v 1.1 2005/04/19 02:56:03 husq Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>
/***************************************************************************** 
$Log: TimerMilli.nc,v $
Revision 1.1  2005/04/19 02:56:03  husq
Import the micazack and CC2420RadioAck

Revision 1.2  2005/03/02 22:45:01  jprabhu
Added Log CVS-Tag

*****************************************************************************/

interface TimerMilli
{
  command result_t setPeriodic( int32_t millis );
  command result_t setOneShot( int32_t millis );

  command result_t stop();

  command bool isSet();
  command bool isPeriodic();
  command bool isOneShot();
  command int32_t getPeriod();

  event result_t fired();
}

