// $Id: IOSwitchC.nc,v 1.5 2005/08/23 21:25:08 jwhui Exp $

/*									tab:2
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

/*
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

configuration IOSwitchC {
  provides {
    interface PowerSourceStatus;
    interface StdControl;
    interface StdControl as Battery;
    interface StdControl as Charge;
    interface StdControl as PIR;
    interface StdControl as Sounder;
  }
}

implementation {

  components I2CPacketC;
  components IOSwitchM;
  components Main;
  components TimerC;

  Battery = IOSwitchM.Battery;
  Charge = IOSwitchM.Charge;
  PIR = IOSwitchM.PIR;
  PowerSourceStatus = IOSwitchM;
  Sounder = IOSwitchM.Sounder;
  StdControl = I2CPacketC;
  StdControl = IOSwitchM.StdControl;

  IOSwitchM.I2CPacket -> I2CPacketC;
  IOSwitchM.Timer -> TimerC.Timer[ unique("Timer") ];

}

