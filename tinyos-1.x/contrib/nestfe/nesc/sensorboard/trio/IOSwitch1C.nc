//$Id: IOSwitch1C.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 *
 */

/**
 * Configuration file for the first PCA9555 IOSwitch. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

configuration IOSwitch1C {
  provides {
    interface StdControl;
    interface IOSwitch;
    interface IOSwitchInterrupt;
  }
}
implementation
{
  components IOSwitch1M, I2CPacketC, TimerC,
             MSP430InterruptC, MSP430GeneralIOC;

  StdControl = IOSwitch1M;
  IOSwitch = IOSwitch1M;
  IOSwitchInterrupt = IOSwitch1M;

  IOSwitch1M.I2CControl -> I2CPacketC.StdControl;
  IOSwitch1M.I2CPacket -> I2CPacketC;

  IOSwitch1M.InitTimer -> TimerC.Timer[unique("Timer")];
  IOSwitch1M.DebounceTimer -> TimerC.Timer[unique("Timer")];
  IOSwitch1M -> MSP430InterruptC.Port26;
  IOSwitch1M -> MSP430GeneralIOC.Port26;
}

