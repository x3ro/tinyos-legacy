// $Id: DigitalIOC.nc,v 1.1 2005/02/17 01:59:57 idgay Exp $

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
 * Access to the digital I/O facilities of the PCF8574APWR used
 * on the mda300ca board. 
 *
 * @author David Gay <dgay@intel-research.net>
 */
configuration DigitalIOC {
  provides {
    interface DigitalIO;
    interface StdControl;
  }
}
implementation {
  components DigitalIOM, I2CPkt as I2CPacketC;

  DigitalIO = DigitalIOM;
  StdControl = DigitalIOM;
  StdControl = I2CPacketC;

  DigitalIOM.I2CPacket -> I2CPacketC.I2CPacket[63];
  DigitalIOM.I2CComplete -> I2CPacketC;
}
