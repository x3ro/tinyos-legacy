// $Id: PIC18F4620I2CC.nc,v 1.1 2005/04/29 12:42:54 hjkoerber Exp $
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
 * $Revision: 1.1 $
 *
 * Primitives for accessing the hardware I2C module on PIC18F4620 microcontrollers.
 * This configuration assumes that the bus is available and reserved 
 * prior to use; aka Bus Arbitration occurs before start() is called.
 * Once the bus is acquired, call start() and then the commands in this module
 * may be used.  Likewise, stop() should be called before releasing the bus.
 */

configuration PIC18F4620I2CC
{
  provides {
    interface StdControl;
    interface PIC18F4620I2C;
    interface I2CPacket;
  }
}
implementation
{
  components HPLMSSPC, PIC18F4620I2CM as I2CM;

  StdControl = I2CM;
  PIC18F4620I2C = I2CM;
  I2CPacket = I2CM;

  I2CM.MSSPControl -> HPLMSSPC;
  I2CM.HPLI2CInterrupt -> HPLMSSPC;
}

