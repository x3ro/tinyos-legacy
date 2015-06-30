/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
 /**
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
includes ulla;
includes Lu;
includes msg_type;
includes UQLCmdMsg;
includes hardware;
includes TosTime;

#define NUM_FIELDS 4
#define NUM_TEST 2000
module RemoteLuM {
  provides {
     interface StdControl;
  }
  uses {

    interface UqpIf;
    interface UcpIf;
    interface Send[uint8_t id];
    interface Receive[uint8_t id];
    
    interface Leds;
    interface Timer;
#ifndef NO_LINKUSER
    #ifdef TELOS_PLATFORM
    interface LocalTime;
    #endif
    #ifdef MICA2_PLATFORM
    interface StdControl as TimeControl;
    interface Time;
    interface TimeUtil;
    #endif
#endif
#ifdef TEST_LINK_USER
    interface TestLinkUser as User1;
    interface TestLinkUser as User2;
#endif

    interface StdControl as CommStdControl;
    interface StdControl as TimeControl;
    interface SendMsg;
  }
}

implementation {

  bool gfSendBusy;
  uint32_t counter;
  uint8_t rcv_counter;
  uint32_t timer_counter;
  uint32_t time_start, time_stop;
  TOS_Msg buf;
  TOS_Msg *msg;
  tos_time_t t0, t1, td;
  
  uint8_t msg_index;
  uint8_t user_index;


  typedef struct TimeMsg {
  //uint32_t timestamp;
    uint32_t time_start;
    uint32_t time_stop;
    uint32_t time_diff;

} TimeMsg;

  void sendQuery();
  
  command result_t StdControl.init() {
    atomic {
      gfSendBusy = FALSE;
      counter = 0;
      timer_counter = 0;
      rcv_counter = 0;
      msg_index = 0;
      msg = &buf;
    }
#ifndef NO_LINKUSER
  #ifdef MICA2_PLATFORM
    call TimeControl.init();
  #endif
#endif
    call CommStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {

    call CommStdControl.start();
#ifndef NO_LINKUSER
  #ifdef MICA2_PLATFORM
    call TimeControl.start();
  #endif
#endif
    dbg(DBG_USR1,"RemoteLuM starts\n");
    if (TOS_LOCAL_ADDRESS == 0) {
      //post sendQuery();
      call Timer.start(TIMER_ONE_SHOT, 1000);
      //call Timer.start(TIMER_REPEAT, 1);
    }

    return SUCCESS;
  }
#ifndef NO_LINKUSER
  task void sendTimeStamp (){
    struct TimeMsg *times = (struct TimeMsg *)&buf.data;
    uint8_t i;
    //call Leds.set(7);
    times->time_start = 1234567890;

#ifdef TELOS_PLATFORM
    times->time_stop = call LocalTime.read();
#endif
#ifdef MICA2_PLATFORM
    times->time_stop = call Time.getLow32();
#endif
    times->time_diff = times->time_stop - time_start;
    call SendMsg.send(TOS_UART_ADDR, sizeof(struct TimeMsg), &buf);
  }
#endif
  void sendQuery() {
    struct QueryMsgNew query;
    struct QueryMsgNew *test;

#ifndef NO_LINKUSER

      post sendTimeStamp();
#else
      dbg(DBG_USR1,"LocalLuM: sendQuery.stop()\n");
#endif

    test = (struct QueryMsgNew *)msg->data;
	
	query.ruId = 1;
	query.msgType = ADD_MSG;
	query.dataType = FIELD_MSG;
	query.queryType = 1;
	query.index = 1;
	query.className = 5;
	query.numFields = NUM_FIELDS;
	query.numConds = 0;
	query.interval = 0;
	query.nsamples = 1;
	
	/* firmware attributes: RSSI, LQI, FREQUENCY, SIGNAL_POWER, CHANNEL, BATTERY */
	query.u.fields[0] = LINK_ID;
	query.u.fields[1] = TYPE;
	
	query.u.fields[2] = LP_ID;
	query.u.fields[3] = STATE;
	query.u.fields[4] = MODE;
	query.u.fields[5] = NETWORK_NAME;
	query.u.fields[6] = RX_ENCRYPTION;
	query.u.fields[7] = TX_ENCRYPTION;
	//dbg(DBG_USR1,"RemoteLuM starts %d\n",(**test).fields[0]);
	dbg(DBG_USR1,"RemoteLuM:requestInfo %d\n",counter);
	
	test = &query;
	//dbg(DBG_USR1,"RemoteLuM: data %d %d\n",test->qid, test->ttl);
	memcpy(msg->data, test, sizeof(struct QueryMsgNew));
	dbg(DBG_USR1,"RemoteLuM: data %d %d\n",msg->data[0], msg->data[1]);
	//call UqpIf.requestInfo[1](0, test, &result);
	call SendMsg.send(0x01, sizeof(struct QueryMsgNew), msg);
  }

  event result_t Timer.fired() {
    struct QueryMsgNew *q = (struct QueryMsgNew *)buf.data;
    struct CmdDescr_t cmddescr;
#ifndef NO_LINKUSER
  #ifdef TELOS_PLATFORM
    atomic time_start = call LocalTime.read();
  #endif
  #ifdef MICA2_PLATFORM
    atomic time_start = call Time.getLow32();
  #endif
#endif

#ifdef TEST_LINK_USER

      //struct CommandMsg *c = (struct CommandMsg *)buf.data;
      call User1.putQuery(q,msg_index);
      //call User1.putCommand(c);
      user_index = 1;
#endif
    dbg(DBG_USR1, "RemoteLuM: Timer.fired\n");
    //sendQuery();
    //post sendQuery();
    //call SendMsg.send(TOS_UART_ADDR, sizeof(struct TimeMsg), &buf);

    return SUCCESS;
  }
  
  event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr pmsg, void* payload, uint16_t payloadLen) {
    dbg(DBG_USR1, "RemoteLuM: receive result\n");

#ifndef NO_LINKUSER
    if (counter < NUM_TEST) {
      sendQuery();
    }
#endif

    return pmsg;
  }
  
  command result_t StdControl.stop() {
    call CommStdControl.stop();
    return SUCCESS;
  }

  /*------------------------------------- UQP ------------------------------------*/
  
  //event result_t UqpIf.requestInfoDone(ullaResult_t *result, uint8_t numBytes) {
	event result_t UqpIf.requestInfoDone(ResultTuple *result, uint8_t numBytes) {
    //check if id is remote user
    //dbg(DBG_USR1, "LocalLuM: UQPIf.requestInfoDone id %d\n",id);
    //call Leds.yellowToggle();
    //if (id == REMOTE_QUERY) {
      // need to reset ulla_result after getting value
      call UqpIf.clearResult();
      dbg(DBG_USR1,"LocalLuM: UqpIf.requestInfoDone\n");
    //}
    return SUCCESS;
  }

  /*------------------------------------- UCP -----------------------------------*/

  event result_t UcpIf.doCmdDone(CmdDescrPtr cmddescr) {
    dbg(DBG_USR1, "LocalLuM: UcpIf.doCmdDone\n");
    return SUCCESS;
  }
  event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
#ifdef TEST_LINK_USER
    struct QueryMsgNew *q = (struct QueryMsgNew *)buf.data;
    struct CommandMsg *c = (struct CommandMsg *)buf.data;
#endif
    atomic gfSendBusy = FALSE;
    
#ifdef TEST_LINK_USER
        dbg(DBG_USR1, "Send Msg %d done\n", msg_index);
        msg_index++;
        if (msg_index < 4 && user_index == 1) { // default number for now: 1 field and 3 conditions
          //call User1.putQuery(q, msg_index);
          ///call Timer.start(TIMER_ONE_SHOT, 10000);
        }
        if (msg_index >= 4 && user_index == 1) {
          msg_index = 0;
          user_index = 2;
          dbg(DBG_USR1, "----------------------------User2 starts\n");
        }
        if (user_index == 2 && msg_index < 3){
          call User2.putQuery(q, msg_index);
        }
#endif

    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    return SUCCESS;
  }

}
