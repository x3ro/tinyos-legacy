/**
 * Provides a library module for handling basic application messages for
 * controlling a wireless sensor network.
 * 
 * @file      XCommand.nc
 * @author    Martin Turon
 * @version   2004/10/1    mturon      Initial version
 *
 * Summary of XSensor commands:
 *      reset, sleep, wakeup
 *  	set/get (rate) "heartbeat"
 *  	set/get (nodeid, group)
 *  	set/get (radio freq, band, power)
 *  	actuate (device, state)
 *  	set/get (calibration)
 *  	set/get (mesh type, max resend)
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: XCommand.nc,v 1.1 2004/12/16 06:01:07 mturon Exp $
 */

includes XCommand;

/**
 * This interface defines callback routines for command messages 
 * received by the mote.  All commands are sent to the application 
 * for handling.
 *
 * @return SUCCESS if application can handle the request; FAIL otherwise
 *
 * @author Martin Turon
 */
interface XCommand
{ 
  /** All commands that are received send this handler */
  event result_t received(XCommandOp *op);

/*
  event result_t cmdSleep();
  event result_t cmdWakeup();

  // ** Timer control messages
  event result_t cmdSetRate(uint32_t newrate);

  event uint32_t cmdGetRate();

  // ** XEE control messages 
  event result_t cmdSetNodeid(uint16_t);
  event uint16_t cmdGetNodeid();
  event result_t cmdSetGroup(uint16_t);
  event uint16_t cmdGetGroup();

  event result_t cmdSetRadioPower(uint16_t);
  event uint16_t cmdGetRadioPower();
  event result_t cmdSetRadioBand(uint16_t);
  event uint16_t cmdGetRadioBand();

  // ** Actuation messages 
  event result_t cmdActuate(uint16_t device, uint16_t state);
*/

}
