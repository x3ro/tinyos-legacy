// $Id: NetProgM.nc,v 1.1.1.1 2007/11/05 19:11:24 jpolastre Exp $

/*									tab:2
 *
 *
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
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module NetProgM {
  provides {
    interface NetProg;
    interface StdControl;
  }
  uses {
    interface DelugeStorage as Storage;
    interface InternalFlash as IFlash;
    interface ReceiveMsg;
    interface SendMsg;
    interface SharedMsgBuf;
    interface SplitControl as MetadataControl;
    command void writeTosInfo();
  }
}

implementation {

  command result_t StdControl.init() {
    call MetadataControl.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() { 
    call MetadataControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() { return SUCCESS; }
  
  event result_t MetadataControl.initDone() { return SUCCESS; }
  event result_t MetadataControl.startDone() { return SUCCESS; }
  event result_t MetadataControl.stopDone() { return SUCCESS; }

  command result_t NetProg.reboot() {
#ifndef PLATFORM_PC
    atomic {
      call writeTosInfo();
      netprog_reboot();
    }
#endif
    return FAIL;
  }
  
  command result_t NetProg.programImgAndReboot(imgnum_t newImgNum) {

#ifndef PLATFORM_PC
    tosboot_args_t args;
    
    atomic {
      call writeTosInfo();
      
      args.imageAddr = call Storage.imgNum2Addr(newImgNum);
      args.gestureCount = 0xff;
      args.noReprogram = FALSE;
      call IFlash.write((uint8_t*)TOSBOOT_ARGS_ADDR, &args, sizeof(args));
      
      // reboot
      netprog_reboot();
    }
#endif

    // couldn't reboot
    return FAIL;

  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pMsg) {

    NetProgMsg* rxMsg = (NetProgMsg*)pMsg->data;

    if (rxMsg->sourceAddr == TOS_UART_ADDR 
	|| rxMsg->sourceAddr == TOS_BCAST_ADDR) {
      if (!call SharedMsgBuf.isLocked()) {
	TOS_MsgPtr pMsgBuf = call SharedMsgBuf.getMsgBuf();
	NetProgMsg* txMsg = (NetProgMsg*)pMsgBuf->data;
	txMsg->sourceAddr = TOS_LOCAL_ADDRESS;
	memcpy(&(txMsg->ident), &G_Ident, sizeof(G_Ident));
	if (call SendMsg.send(rxMsg->sourceAddr, sizeof(NetProgMsg), pMsgBuf) == SUCCESS)
	  call SharedMsgBuf.lock();
      }
    }
    
    return pMsg;

  }

  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t result) {
    call SharedMsgBuf.unlock();
    return SUCCESS;
  }
  
  event void Storage.loadImagesDone(result_t result) {}
  event void SharedMsgBuf.bufFree() {}

}
