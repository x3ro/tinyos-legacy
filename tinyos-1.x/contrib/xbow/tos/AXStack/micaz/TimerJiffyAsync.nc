//$Id: TimerJiffyAsync.nc,v 1.1 2005/04/19 02:56:03 husq Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

/*
 *
 * $Log: TimerJiffyAsync.nc,v $
 * Revision 1.1  2005/04/19 02:56:03  husq
 * Import the micazack and CC2420RadioAck
 *
 * Revision 1.2  2005/03/02 22:34:16  jprabhu
 * Added Log-tag for capturing changes in files.
 *
 *
 */

interface TimerJiffyAsync
{
  async command result_t setOneShot( uint32_t jiffy );

  async command result_t stop();

  async command bool isSet();

  async event result_t fired();
}

