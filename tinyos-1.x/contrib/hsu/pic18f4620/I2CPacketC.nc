// $Id: I2CPacketC.nc,v 1.1 2005/04/29 12:48:42 hjkoerber Exp $
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
 * Provides the ability to write or read a series of bytes to/from the
 * I2C bus.  
 **/
configuration I2CPacketC
{
  provides {
    interface StdControl;
    interface I2CPacket;
  }
}
implementation {
  components I2CPacketM, PIC18F4620I2CC as I2C, BusArbitrationC;

  StdControl = BusArbitrationC;
  StdControl = I2CPacketM;
  I2CPacket = I2CPacketM.I2CPacket;

  I2CPacketM.LPacket -> I2C;
  I2CPacketM.LControl -> I2C;

  I2CPacketM.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];

}
