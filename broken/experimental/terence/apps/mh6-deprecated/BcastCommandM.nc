/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: BcastCommandM.nc,v 1.1 2003/03/19 01:11:50 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Simple Broad Cast Protocol used for one to many communication 
 * on top of virtual comm
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/

module BcastCommandM {
  provides {
    interface HandleBcast;
  }
  uses {
    interface VCSend;
    interface VCExtractHeader;
    interface ReceiveMsg as ReceiveBcastMsg;
  }

}
implementation {
  uint8_t sending;
  int8_t lastSeqnum;
  
  typedef struct BcastCmdMsg {
    uint8_t seqnum;
  } BcastCmdMsg;
  
  /*////////////////////////////////////////////////////////*/
  /**
   * Bcast Message has header as follow AM Header, VC Header, BCast Header, data
   * @author: terence
   * @param: tos message that you want to see where in the message is the data
   * concerned
   * @return: pointer to the data (stripped off all the header)
   */

  command uint8_t* HandleBcast.extractData(TOS_MsgPtr msg) {
    uint8_t *bcastHeader = call VCExtractHeader.extractData(msg);
    return &bcastHeader[sizeof(BcastCmdMsg)];
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * A node receive the message. this will make sure that we are only 
   * going to bcast a message once
   * @author: terence
   * @param: msg, the bcast msg we received
   * @return: msg, the bcast msg we received
   */
  
  event TOS_MsgPtr ReceiveBcastMsg.receive(TOS_MsgPtr msg) {
    struct BcastCmdMsg *bcm = (struct BcastCmdMsg *) call VCExtractHeader.extractData(msg);
    // ignore if this is old
    if ((bcm->seqnum - lastSeqnum) <= 0) return msg;
    // save it to history
    lastSeqnum = bcm->seqnum;
    // signal up to handle the message;
    signal HandleBcast.execute(msg);
    // if i am sending, then don't send it
    if (sending == 1) return msg;
    // send it out if all goes well
    sending = call VCSend.send(TOS_BCAST_ADDR, msg->length, msg);
    return msg;
  }
  event void VCSend.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    sending = 0;
  }
  event uint8_t VCSend.sendDoneFailException(TOS_MsgPtr msg) {
    // no retranmission
    return 0;
  }

  


}
