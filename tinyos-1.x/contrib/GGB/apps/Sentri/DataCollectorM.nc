// $Id: DataCollectorM.nc,v 1.1 2006/12/01 00:09:07 binetude Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

includes SysAlarm;
module DataCollectorM
{
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer;
    interface SendMsg as SendUART;

    interface Receive as ReceiveCmd;
    interface RouteControl;
    interface Send as SendReply;
    interface FixRoute;
    interface MacControl;

    interface AllocationReq as ProfileAllocReq;
    interface WriteData;
    interface ReadData;
    interface LogData;

//    interface LocalTime;
    interface SysTime;
    interface SysAlarm;
    interface GlobalTime;
    interface StdControl as TimeSyncControl;

    interface SampleLog;
  }
}
implementation
{
  enum {
    RADIUS_OF_INTERFERENCE = 5,
#if defined(PLATFORM_MICA2)
    RADIO_DELAY = (TOSH_DATA_LENGTH * 7 + 234) / 19,
#elif defined(PLATFORM_TELOSB) || defined(PLATFORM_MICAZ)
    RADIO_DELAY = (TOSH_DATA_LENGTH * 7 + 234) / 19,
#endif
  };

  dataPrfl dp;
  uint8_t state;

  uint8_t cmdBffr[TOSH_DATA_LENGTH];
  CmdMsg *cmd;

  TOS_Msg replyBffr;
  uint16_t replyLength;
  ReplyMsg *reply;

  bool toUART;

  uint8_t lastState;



  result_t sendReply();
  result_t sendDoneCmn();
  result_t chk(result_t success) {
    if (!success) {
      call Leds.redOff();
      call Leds.yellowOff();
      if (lastState == IDLE_STATE) lastState = state;
      state = IDLE_STATE;
    }
    return success;
  }



  //  StdControl, Miscellaneous  //
  command result_t StdControl.init() {
    call ProfileAllocReq.request(sizeof(dataPrfl));
    call Leds.init();
    cmd = (CmdMsg *)cmdBffr;
    return SUCCESS;
  }
  command result_t StdControl.start() {
    reply = (ReplyMsg *) call SendReply.getBuffer(&replyBffr, &replyLength);
    state = IDLE_STATE;
    lastState = IDLE_STATE;
    call MacControl.enableAck();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    //  PING_NODE, FIND_NODE, READ_PROFILE1, READ_PROFILE2,  //
    //  TIMESYNC_INFO, NETWORK_INFO, FOR_DEBUG  //
    sendReply(); 
    return SUCCESS;
  }



  //  Handler for each command  //
  result_t esCmn() {
    //  PING_NODE, READ_PROFILE1, READ_PROFILE2, TIMESYNC_INFO, NETWORK_INFO  //
    toUART = cmd->args.es.toUART;
    return SUCCESS;
  }
  result_t findNode() {
    uint8_t i;
    for (i = 0; i < cmd->args.fn.noOfNode; i++)
      if (cmd->args.fn.nodes[i] == TOS_LOCAL_ADDRESS)
        break;
    if (i == cmd->args.fn.noOfNode) {
      return chk(call Timer.start(TIMER_ONE_SHOT,
        RADIUS_OF_INTERFERENCE * RADIO_DELAY));
    } else {
      state = IDLE_STATE;
      return SUCCESS;
    }
  }
  result_t eraseFlash() {
    call Leds.redOn();
    return chk(call SampleLog.erase());
  }
  result_t startSensing() {
    //  START_SENSING  //
    uint8_t i;
    uint32_t startTime;
    call Leds.redOn();

    dp.seqNo = cmd->seqNo;
    dp.nSamples = cmd->args.ss.nSamples;
    dp.intrv = cmd->args.ss.intrv;
    dp.chnlSelect = cmd->args.ss.chnlSelect;
    dp.samplesToAvg = cmd->args.ss.samplesToAvg;
    dp.startTime = cmd->args.ss.startTime;
    dp.integrity = 2;
    dp.lenOfNm = cmd->args.ss.lenOfNm;
    if (dp.lenOfNm > MAX_START_SENSING_NAME)
      dp.lenOfNm = MAX_START_SENSING_NAME;
    for (i = 0; i < dp.lenOfNm; i++)
      dp.nm[i] = cmd->args.ss.nm[i];

    startTime = dp.startTime;
    if (call GlobalTime.global2Local(&startTime)) {
      if (!(call SysAlarm.set(SYSALARM_ABSOLUTE, startTime))) {
        call Leds.redOff();
        state = IDLE_STATE;
      }
    } else {
      call Leds.redOff();
      state = IDLE_STATE;
    }
    return SUCCESS;
  }
  result_t readProfileCmn() {
    //  READ_PROFILE1, READ_PROFILE2  //
    call Leds.yellowOn();
    esCmn();
    return chk(call ReadData.read(0, (uint8_t *)&dp, sizeof(dataPrfl)));
  }
  result_t timesyncInfo() {
    esCmn();
    reply->args.tir.sysTime = call SysTime.getTime32();
//    reply->args.tir.localTime = call LocalTime.read();
    call GlobalTime.getGlobalTime(&(reply->args.tir.globalTime));
    return chk(call Timer.start(TIMER_ONE_SHOT,
      RADIUS_OF_INTERFERENCE * RADIO_DELAY));
  }
  result_t networkInfo() {
    esCmn();
    reply->args.nir.parent = call RouteControl.getParent();
    reply->args.nir.treeParent = call FixRoute.getParent();
    reply->args.nir.depth = call RouteControl.getDepth();
    reply->args.nir.treeDepth = call FixRoute.getDepth();
    reply->args.nir.occupancy = call RouteControl.getOccupancy();
    reply->args.nir.quality = call RouteControl.getQuality();
    reply->args.nir.fixedRoute = call FixRoute.getFixedRoute();
    return chk(call Timer.start(TIMER_ONE_SHOT,
      RADIUS_OF_INTERFERENCE * RADIO_DELAY));
  }
  result_t forDebug() {
    toUART = cmd->args.fd.toUART;
    reply->args.fdr.type = lastState;
    return chk(call Timer.start(TIMER_ONE_SHOT,
      RADIUS_OF_INTERFERENCE * RADIO_DELAY));
  }
  result_t reset() {
    int i;
    call Leds.redOn();
    dp.seqNo = 0;
    dp.nSamples = 0;
    dp.intrv = 0;
    dp.chnlSelect = 0;
    dp.samplesToAvg = 0;
    dp.startTime = 0;
    dp.integrity = 0;
    dp.lenOfNm = 0;
    for (i = 0; i < MAX_START_SENSING_NAME; i++) dp.nm[i] = 0;
    chk(call WriteData.write(0, (uint8_t *)&dp, sizeof(dataPrfl)));
    return SUCCESS;
  }



  //  Receive and interpret command  //
  task void cmdIntpr() {
    switch (cmd->type) {
    case LED_ON:
      call Leds.redOn();
      state = IDLE_STATE;
      break;
    case LED_OFF:
      call Leds.redOff();
      state = IDLE_STATE;
      break;

    case PING_NODE:
      esCmn();
      chk(call Timer.start(TIMER_ONE_SHOT,
        RADIUS_OF_INTERFERENCE * RADIO_DELAY));
      break;
    case FIND_NODE:
      findNode();
      break;

    case RESET:
      reset();
      break;
    case ERASE_FLASH:
      eraseFlash();
      break;
    case START_SENSING:
      startSensing();
      break;

    case READ_PROFILE1:
    case READ_PROFILE2:
      readProfileCmn();
      break;

    case TIMESYNC_INFO:
      timesyncInfo();
      break;
    case NETWORK_INFO:
      networkInfo();
      break;

    case FIX_ROUTE:
      call FixRoute.fix();
      state = IDLE_STATE;
      break;
    case RELEASE_ROUTE:
      call FixRoute.release();
      state = IDLE_STATE;
      break;
    case TIMESYNC_ON:
//      call TimeSyncControl.start();
      state = IDLE_STATE;
      break;
    case TIMESYNC_OFF:
//      call TimeSyncControl.stop();
      state = IDLE_STATE;
      break;

    case FOR_DEBUG:
      forDebug();
      break;

    default:
      break;
    }
  }
  event TOS_MsgPtr ReceiveCmd.receive(TOS_MsgPtr msg, void *payload,
    uint16_t payloadLen) {
    CmdMsg *tmpCmd = (CmdMsg *)payload;
    
    if ((tmpCmd->dest != TOS_BCAST_ADDR)
      && (tmpCmd->dest != TOS_LOCAL_ADDRESS))
      return msg;
    if (state != IDLE_STATE) return msg;
    if ((TOS_LOCAL_ADDRESS == 0) && (tmpCmd->type != TIMESYNC_INFO))
      return msg;

    memcpy(cmdBffr, payload, payloadLen);
    state = cmd->type;

    call Leds.greenToggle();
    post cmdIntpr();
    return msg;
  }



  //  Send reply  //
  result_t sendReply() {
    //  PING_NODE, FIND_NODE, READ_PROFILE1, READ_PROFILE2,  //
    //  TIMESYNC_INFO, NETWORK_INFO, FOR_DEBUG  //
    result_t retVal;
    reply->src = TOS_LOCAL_ADDRESS;
    reply->type = cmd->type;
    if (toUART) {
      retVal = call SendUART.send(TOS_UART_ADDR,  TOSH_DATA_LENGTH,
        &replyBffr);
    } else {
      retVal = call SendReply.send(&replyBffr, sizeof(ReplyMsg));
    }
    return retVal ? SUCCESS : sendDoneCmn();
  }
  result_t sendDoneCmn() {
    //  PING_NODE, FIND_NODE, READ_PROFILE1, READ_PROFILE2,  //
    //  TIMESYNC_INFO, NETWORK_INFO, FOR_DEBUG  //
    switch (cmd->type) {
    case READ_PROFILE1:
    case READ_PROFILE2:
      call Leds.yellowOff();
      break;
    default:
      break;
    }
    state = IDLE_STATE;
    return SUCCESS;
  }
  event result_t SendReply.sendDone(TOS_MsgPtr msg, result_t success) {
    return sendDoneCmn();
  }
  event result_t SendUART.sendDone(TOS_MsgPtr msg, result_t success) {
    return sendDoneCmn();
  }



  //  EEPROM part for Data Profile (DP) access  //
  event result_t ProfileAllocReq.requestProcessed(result_t success) {
    // from init()
    return SUCCESS;
  }
  event result_t WriteData.writeDone(uint8_t *data, uint32_t numBytesWrite,
    result_t success) {
    //  ERASE_FLASH, START_SENSING, RESET  //
    chk(call LogData.sync());
    return SUCCESS;
  }
  event result_t ReadData.readDone(uint8_t* buffer, uint32_t numBytesRead,
    result_t success) {
    uint8_t i;
    switch (cmd->type) {
    case READ_PROFILE1:
      reply->args.rp1r.seqNo = dp.seqNo;
      reply->args.rp1r.nSamples = dp.nSamples;
      reply->args.rp1r.intrv = dp.intrv;
      reply->args.rp1r.chnlSelect = dp.chnlSelect;
      reply->args.rp1r.samplesToAvg = dp.samplesToAvg;
      reply->args.rp1r.startTime = dp.startTime;
      reply->args.rp1r.integrity = dp.integrity;
      return chk(call Timer.start(TIMER_ONE_SHOT,
        RADIUS_OF_INTERFERENCE * RADIO_DELAY));
      break;
    case READ_PROFILE2:
      reply->args.rp2r.lenOfNm = dp.lenOfNm;
      if (reply->args.rp2r.lenOfNm > MAX_READ_PROFILE2_REPLY_NAME)
        reply->args.rp2r.lenOfNm = MAX_READ_PROFILE2_REPLY_NAME;
      for (i = 0; i < reply->args.rp2r.lenOfNm; i++)
        reply->args.rp2r.nm[i] = dp.nm[i];
      return chk(call Timer.start(TIMER_ONE_SHOT,
        RADIUS_OF_INTERFERENCE * RADIO_DELAY));
      break;
    default:
      break;
    }
    return SUCCESS;
  }
  event result_t LogData.eraseDone(result_t success) {
    //  never called  //
    return SUCCESS;
  }
  event result_t LogData.appendDone(uint8_t* data, uint32_t numBytes,
    result_t success) {
    //  never called  //
    return SUCCESS;
  }
  event result_t LogData.syncDone(result_t success) {
    //  ERASE_FLASH, START_SENSING, RESET  //
    call Leds.redOff();
    state = IDLE_STATE;
    return SUCCESS;
  }



  //  Timesync  //
  task void procAlarm() {
    //  START_SENSING  //
    chk(call SampleLog.prepare(&dp));
  }
  async event void SysAlarm.fired() {
    post procAlarm();
  }



  //  Call sub-components  //
  event result_t SampleLog.ready(result_t success) {
    //  START_SENSING  //
    chk(call SampleLog.start());
    return SUCCESS;
  }
  event result_t SampleLog.done(result_t success) {
    //  START_SENSING  //
    chk(call WriteData.write(0, (uint8_t *)&dp, sizeof(dataPrfl)));
    return SUCCESS;
  }
  event result_t SampleLog.eraseDone(result_t success) {
    //  ERASE_FLASH  //
    dp.integrity = 1;
    chk(call WriteData.write(0, (uint8_t *)&dp, sizeof(dataPrfl)));
    return SUCCESS;
  }
}

