// $Id: AD5242Bus1C.nc,v 1.1 2005/06/02 00:42:43 jaein Exp $
/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 * Revision:  $Revision: 1.1 $
 *
 * AD5242Bus1C provides access to primitives for the AD5242 
 * dual-channel digital potentiometer.  It provides interface AD5242
 * for digital commands to and from the potentiometer.  StdControl
 * sets the physical hardware pin to turn the device on or off via the
 * shutdown pin (if supported by the underlying platform).
 *
 * You *must* define the "AD524X_SD" pin in an included file, presumably
 * your sensorboard.h file.  The AD524X_SD pin is used to put the device
 * into and out of shutdown when StdControl start() and stop() are called.
 * These functions:
 *   TOSH_MAKE_AD524X_SD_OUTPUT()
 *   TOSH_MAKE_AD524X_SD_INPUT()
 *   TOSH_SET_AD524X_SD_PIN()
 *   TOSH_CLR_AD524X_SD_PIN()
 * May be defined as empty functions for platforms that do not support the
 * AD524X shutdown pin.
 *
 * The AD524X driver counts the number of users for systems with multiple
 * pots and only causes the physical pin to initiate a shutdown when all
 * users of the pot have called stop (in other words #start() == #stop())
 *
 * It is recommended that you use the SD bit in the AD524X by calling
 * AD5242.start() and AD5242.stop() rather than toggling the actual
 * shutdown pin.  By setting the pin in the particular device, you can
 * ensure that device has been shutdown.
 */

configuration AD5242Bus1C {
  provides {
    interface StdControl;
    interface AD5242;
  }
}
implementation
{
  components I2CPacketC, AD5242Bus1M;

  AD5242 = AD5242Bus1M;
  StdControl = AD5242Bus1M;

  AD5242Bus1M.LowerControl -> I2CPacketC;
  AD5242Bus1M.I2CPacket -> I2CPacketC;
}
