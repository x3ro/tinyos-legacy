// $Id: AnalogIOC.nc,v 1.2 2005/02/17 02:38:27 idgay Exp $

/*									tab:4
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * A/D and excitation voltage control for the mda300ca (new-style sensor
 * interface).
 *
 * @author David Gay <dgay@intel-research.net>
 */
includes mda300ca;

configuration AnalogIOC
{
  provides {
    interface Sensor[uint8_t port];
    interface Power[uint8_t voltage];
  }
}
implementation
{
  components Main, I2CPkt as I2CPacketC, AnalogIOM;

  Main.StdControl -> AnalogIOM;
  Main.StdControl -> I2CPacketC;

  Sensor = AnalogIOM;
  Power = AnalogIOM;

  AnalogIOM.ADC_I2C -> I2CPacketC.I2CPacket[74];
  AnalogIOM.Switch_I2C -> I2CPacketC.I2CPacket[75];
  AnalogIOM.I2CComplete -> I2CPacketC;
}
