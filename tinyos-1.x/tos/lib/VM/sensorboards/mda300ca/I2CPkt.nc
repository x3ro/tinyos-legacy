// $Id: I2CPkt.nc,v 1.1 2005/02/17 01:59:57 idgay Exp $

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
 * Extend I2CPacketC with a Completion interface to allow retry of failed
 * I2C packet requests.
 *
 * @author David Gay <dgay@intel-research.net>
 */
configuration I2CPkt
{
  provides {
    interface StdControl;
    interface I2CPacket[uint8_t id];
    interface Completion;
  }
}

implementation {
  components I2CPacketC, I2CCompleteM;

  StdControl = I2CPacketC;
  I2CPacket = I2CPacketC;
  Completion = I2CCompleteM;

  I2CCompleteM.I2CPacket -> I2CPacketC;
}
