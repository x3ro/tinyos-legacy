// $Id: I2CCompleteM.nc,v 1.1 2005/02/17 01:59:57 idgay Exp $

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
 * Provide a Completion interface for I2CPacketC (which doesn't have one) -
 * we simply check the completion of all packets.
 *
 * @author David Gay <dgay@intel-research.net>
 */
module I2CCompleteM {
  provides interface Completion;
  uses interface I2CPacket[uint8_t id];
}
implementation
{
  event result_t I2CPacket.readPacketDone[uint8_t id](char len, char *data) {
    signal Completion.done();
    return SUCCESS;
  }

  event result_t I2CPacket.writePacketDone[uint8_t id](bool result) {
    signal Completion.done();
    return SUCCESS;
  }
}
