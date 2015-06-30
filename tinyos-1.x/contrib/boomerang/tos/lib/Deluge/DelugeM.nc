// $Id: DelugeM.nc,v 1.1.1.1 2007/11/05 19:11:24 jpolastre Exp $

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

module DelugeM {
  provides {
    interface StdControl;
  }
  uses {
    interface Crc;
    interface DelugeMetadata as Metadata;
    interface DelugePageTransfer as PageTransfer;
    interface Leds;
    interface InternalFlash as IFlash;
    interface NetProg;
    interface Random;
    interface ReceiveMsg as ReceiveAdvMsg;
    interface SendMsg as SendAdvMsg;
    interface SharedMsgBuf as Buf1;
    interface SharedMsgBuf as Buf2;
    interface SplitControl as MetadataControl;
    interface StdControl as PageTransferControl;
    interface Timer;
  }
}

implementation {

  enum {
    DELUGE_NUM_TIMERS = DELUGE_NUM_IMAGES,
  };

  enum {
    S_INITIALIZING,
    S_STARTED,
    S_STOPPED,
  };

  uint8_t state;
  uint8_t rebootDelay;
  uint8_t curImage;
  bool imagesLoaded;
  
  DelugeAdvTimer advTimers[DELUGE_NUM_TIMERS];
  DelugeNodeDesc nodeDesc;

  int findMinTimer() {

    int minTimer = 0;
    int i;

    for ( i = 1; i < DELUGE_NUM_TIMERS; i++ ) {
      if (advTimers[i].timer < advTimers[minTimer].timer)
	minTimer = i;
    }
    
    return minTimer;

  }

  void setupAdvTimer(int timerNum) {

    int minTimer;

    advTimers[timerNum].timer = (uint32_t)0x1 << (advTimers[timerNum].periodLog2-1);
    advTimers[timerNum].timer += call Random.rand() & (advTimers[timerNum].timer-1);
    advTimers[timerNum].overheard = 0;

    minTimer = findMinTimer();
    
    call Timer.stop();
    call Timer.start(TIMER_ONE_SHOT, advTimers[minTimer].timer);

  }

  void updateTimers(int minTimer) {
    int i;
    for ( i = 0; i < DELUGE_NUM_TIMERS; i++ ) {
      if ((advTimers[i].timer - 2) >= advTimers[minTimer].timer)
	advTimers[i].timer -= advTimers[minTimer].timer;
    }
  }

  void resetTimer(int i) {
    if ( i < DELUGE_NUM_IMAGES &&
	 advTimers[i].periodLog2 != DELUGE_MIN_ADV_PERIOD_LOG2 ) {
      advTimers[i].periodLog2 = DELUGE_MIN_ADV_PERIOD_LOG2;
      setupAdvTimer(i);
    }
  }

  void checkReboot() {
    DelugeImgDesc* imgDesc = call Metadata.getImgDesc(nodeDesc.imgNum);
    if ( nodeDesc.uid == imgDesc->uid
	 && imgDesc->numPgsComplete == imgDesc->numPgs
	 && imgDesc->numPgs )
      rebootDelay = DELUGE_REBOOT_DELAY;
  }

  void setNextPage() {

    DelugeImgDesc *imgDesc;
    int i;

    for ( i = 0; i < DELUGE_NUM_IMAGES; i++ ) {
      imgDesc = call Metadata.getImgDesc(i);
      if (imgDesc->numPgs != imgDesc->numPgsComplete) {
	call PageTransfer.setWorkingPage(i, imgDesc->numPgsComplete);
	advTimers[i].newAdvs = DELUGE_NUM_NEWDATA_ADVS_REQUIRED;    
	advTimers[i].overheard = 0;
	resetTimer(i);
	call Leds.redOff();
	return;
      }
    }

    call Leds.redOn();
    call PageTransfer.setWorkingPage(DELUGE_INVALID_IMGNUM, DELUGE_INVALID_PGNUM);
    
  }

  command result_t StdControl.init() {

    state = S_INITIALIZING;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)IFLASH_NODE_DESC_ADDR, &nodeDesc, sizeof(nodeDesc));
#endif
    call Leds.init();
    //    call MetadataControl.init();
    call PageTransferControl.init();

    return SUCCESS;

  }

  void realStart() {

    int i;

    setNextPage();
    call PageTransferControl.start();

    for ( i = 1; i < DELUGE_NUM_TIMERS; i++ )
      resetTimer(i);

  }

  command result_t StdControl.start() {

    if ( !call Metadata.isStarted() ) {
      call MetadataControl.start();
    }
    else {
      realStart();
    }

    state = S_STARTED;

    resetTimer( 0 );

    return SUCCESS;

  }

  command result_t StdControl.stop() {
    state = S_STOPPED;
    call Timer.stop();
    call PageTransferControl.stop();
    return SUCCESS;
  }

  event result_t MetadataControl.initDone() {
    return SUCCESS;
  }

  event result_t MetadataControl.startDone() { 
    if ( state == S_STARTED ) {
      realStart();
    }
    imagesLoaded = TRUE;
    return SUCCESS; 
  }

  event result_t MetadataControl.stopDone() { 
    return SUCCESS; 
  }

  bool isNodeDescValid(DelugeNodeDesc* tmpNodeDesc) {
    return ( tmpNodeDesc->crc == call Crc.crc16(tmpNodeDesc, 8)
	     || tmpNodeDesc->vNum == DELUGE_INVALID_VNUM );
  }

  result_t sendAdvMsgBuf(int imgNum, uint16_t addr, TOS_MsgPtr pMsgBuf);

  void sendAdvMsgPC(int imgNum, uint16_t addr) {
    if (!call Buf2.isLocked()) {
      if (sendAdvMsgBuf(imgNum, addr, call Buf2.getMsgBuf()) == SUCCESS)
	call Buf2.lock();
    }
  }

  void sendAdvMsg(int imgNum, uint16_t addr) {
    if (!call Buf1.isLocked()) {
      if (sendAdvMsgBuf(imgNum, addr, call Buf1.getMsgBuf()) == SUCCESS)
	call Buf1.lock();
    }
  }

  result_t sendAdvMsgBuf(int imgNum, uint16_t addr, TOS_MsgPtr pMsgBuf) {
    DelugeAdvMsg *pMsg = (DelugeAdvMsg*)pMsgBuf->data;
    DelugeImgDesc *imgDesc = call Metadata.getImgDesc(imgNum);

    pMsg->sourceAddr = TOS_LOCAL_ADDRESS;
    pMsg->version = DELUGE_VERSION;
    pMsg->type = (imagesLoaded) ? DELUGE_ADV_NORMAL : DELUGE_ADV_ERROR;
    
    // make sure node desc is valid
    if ( !isNodeDescValid( &nodeDesc ) )
      memset( &nodeDesc, 0xff, sizeof( nodeDesc ) );
    memcpy(&pMsg->nodeDesc, &nodeDesc, sizeof(DelugeNodeDesc));
    
    // make sure img desc is valid
    if ( !call Metadata.isImgDescValid( imgDesc ) ) {
      imgDesc->vNum = DELUGE_INVALID_VNUM;
      imgDesc->imgNum = imgNum;
    }
    memcpy(&pMsg->imgDesc, imgDesc, sizeof(DelugeImgDesc));

    pMsg->numImages = DELUGE_NUM_IMAGES;
    if (call SendAdvMsg.send(addr, sizeof(DelugeAdvMsg), pMsgBuf) == SUCCESS) {
      dbg(DBG_USR1, "DELUGE: Sent ADV_MSG(imgNum=%d)\n", imgDesc->imgNum);
      call Leds.greenToggle();
      return SUCCESS;
    }
    return FAIL;

  }

  event result_t Timer.fired() {

    int minTimer = findMinTimer();

    updateTimers(minTimer);

    if (!advTimers[minTimer].overheard)
      sendAdvMsg(minTimer, TOS_BCAST_ADDR);

    if (call PageTransfer.isTransferring())
      advTimers[minTimer].newAdvs = DELUGE_NUM_NEWDATA_ADVS_REQUIRED;
    else if (advTimers[minTimer].newAdvs > 0)
      advTimers[minTimer].newAdvs--;

    if (rebootDelay > 0) {
      call Leds.yellowOn();
      if (!(--rebootDelay)) {
	// will not return on SUCCESS
	call NetProg.programImgAndReboot(nodeDesc.imgNum);
      }
    }
    else {
      call Leds.yellowOff();
      if (advTimers[minTimer].newAdvs == 0
	  && advTimers[minTimer].periodLog2 < DELUGE_MAX_ADV_PERIOD_LOG2) {
	advTimers[minTimer].periodLog2++;
      }
    }

    setupAdvTimer(minTimer);

    return SUCCESS;
    
  }

  event TOS_MsgPtr ReceiveAdvMsg.receive(TOS_MsgPtr pMsg) {
    
    DelugeAdvMsg *rxAdvMsg = (DelugeAdvMsg*)(pMsg->data);
    imgnum_t imgNum = rxAdvMsg->imgDesc.imgNum;

    DelugeImgDesc *cmpImgDesc = &(rxAdvMsg->imgDesc);
    DelugeImgDesc *curImgDesc;
    bool isEqual = FALSE;

    if ( rxAdvMsg->version != DELUGE_VERSION 
	 || !isNodeDescValid(&rxAdvMsg->nodeDesc)
	 || state != S_STARTED )
      return pMsg;

    curImgDesc = call Metadata.getImgDesc(imgNum);

    if (rxAdvMsg->type != DELUGE_ADV_NORMAL) {
      // adv message from PC
      if ( rxAdvMsg->type == DELUGE_ADV_PING
	   || (cmpImgDesc->vNum == curImgDesc->vNum
	       && cmpImgDesc->numPgsComplete == curImgDesc->numPgsComplete)) {
	sendAdvMsg(imgNum, rxAdvMsg->sourceAddr);
	if ( rxAdvMsg->nodeDesc.vNum == nodeDesc.vNum )
	  return pMsg;
      }
      else if ( rxAdvMsg->type == DELUGE_ADV_RESET ) {
	call Metadata.setupNewImage(&(rxAdvMsg->imgDesc));
	return pMsg;
      }
    }

    if ( rxAdvMsg->nodeDesc.vNum != nodeDesc.vNum
	 && rxAdvMsg->nodeDesc.vNum != DELUGE_INVALID_VNUM
	 && rxAdvMsg->nodeDesc.imgNum < DELUGE_NUM_IMAGES ) {
      resetTimer( rxAdvMsg->nodeDesc.imgNum );
      if ( ( rxAdvMsg->nodeDesc.vNum - nodeDesc.vNum) > 0 ) {
	memcpy(&nodeDesc, &rxAdvMsg->nodeDesc, sizeof(DelugeNodeDesc));
#ifndef PLATFORM_PC
	call IFlash.write((uint8_t*)IFLASH_NODE_DESC_ADDR, &nodeDesc, sizeof(nodeDesc));
#endif
	if ( nodeDesc.imgNum == DELUGE_GOLDEN_IMAGE_NUM )
	  rebootDelay = DELUGE_REBOOT_DELAY;
	else
	  checkReboot();
	if (rxAdvMsg->type == DELUGE_ADV_PC)
	  sendAdvMsgPC(imgNum, rxAdvMsg->sourceAddr);
      }
    }

    // don't do anything with the image descriptor if it is corrupt
    //   or if the images have not been mounted
    if ( call Metadata.isImgDescValid(&(rxAdvMsg->imgDesc))
	 && state == S_STARTED ) {

      // don't listen to advertisements about the golden image
      //   unless it's from the PC and source address is TOS_UART_ADDR
      if (imgNum != DELUGE_GOLDEN_IMAGE_NUM
	  || (rxAdvMsg->type == DELUGE_ADV_PC && rxAdvMsg->sourceAddr == TOS_UART_ADDR)) {

	if (cmpImgDesc->vNum != curImgDesc->vNum) {
	  // image is newer
	  if (curImgDesc->vNum == DELUGE_INVALID_VNUM
	      || (cmpImgDesc->vNum != DELUGE_INVALID_VNUM
		  && (cmpImgDesc->vNum - curImgDesc->vNum) > 0)) {
	    call Metadata.setupNewImage(&(rxAdvMsg->imgDesc));
	    call PageTransfer.setWorkingPage(DELUGE_INVALID_IMGNUM, DELUGE_INVALID_PGNUM);
	  }
	}
	// image is larger
	else if (cmpImgDesc->numPgsComplete > curImgDesc->numPgsComplete) {
	  if ( advTimers[imgNum].newAdvs == 0 )
	    call PageTransfer.dataAvailable(rxAdvMsg->sourceAddr, imgNum);
	}
	// image is smaller
	else if (cmpImgDesc->numPgsComplete < curImgDesc->numPgsComplete) {
	  advTimers[imgNum].newAdvs = DELUGE_NUM_NEWDATA_ADVS_REQUIRED;
	}      
	// image is the same
	else {
	  advTimers[imgNum].overheard = 1;
	  isEqual = TRUE;
	}      
	
	if ( !isEqual )
	  resetTimer(imgNum);

      }
    }
    
    return pMsg;

  }

  event result_t SendAdvMsg.sendDone(TOS_MsgPtr pMsg, result_t result) {
    if (pMsg == call Buf1.getMsgBuf()) {
      call Buf1.unlock();
    }
    else if (pMsg == call Buf2.getMsgBuf()) {
      call Buf2.unlock();
    }
    return SUCCESS;
  }

  event void PageTransfer.receivedPage(imgnum_t imgNum, pgnum_t pgNum) {
    curImage = imgNum;
    call Metadata.receivedPage(imgNum, pgNum);
  }

  event void PageTransfer.suppressMsgs(imgnum_t imgNum) {
    advTimers[imgNum].overheard = 1;
  }
  
  event void Metadata.updateDone(result_t result) {
    if ( curImage == nodeDesc.imgNum )
      checkReboot();
    setNextPage();
  }
  
  event void Buf1.bufFree() {}
  event void Buf2.bufFree() {}
  
}
