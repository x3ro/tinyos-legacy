// $Id: LedsC.nc,v 1.1.1.1 2007/11/05 19:11:35 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
/**
 * Configuration for changing the state of the LEDs on a device.
 * Use this configuration, and the Leds interface provided, to set and
 * clear LED lights on the Tmote platforms.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
configuration LedsC {
  provides interface Leds;
}
implementation
{
  components MainLedsC;
  components LedsM, Max7315M, I2CPacketC;
  components new I2CResourceC() as CmdWriteC;

  Leds = LedsM;

  LedsM.LowerControl -> Max7315M;
  LedsM.LedsControl -> Max7315M;

  Max7315M.LowerControl -> I2CPacketC;
  Max7315M.I2CPacket -> I2CPacketC;
  Max7315M.CmdWrite -> CmdWriteC;
}

