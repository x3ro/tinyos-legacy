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
 *
 * LLA implementation
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
 
includes UQLCmdMsg;
includes UllaQuery;
includes Attribute;
includes AMTypes;

module LLAM {

  provides 	{
    interface StdControl;
    interface LinkProviderIf[uint8_t id];  // replacement of RequestUpdate
    interface ProcessCmd as Control;
    interface LinkEstimation;
    interface GetInfoIf as GetLinkInfo;
  }
  uses {
    interface Timer;
    interface Leds;

  	interface ProcessCmd as AttributeEvent;
    interface ProcessCmd as LinkEvent;
    interface ProcessCmd as CompleteCmdEvent;
    
    interface Send as SendScanLinks;
		interface Send as SendGetInfo;
		interface Send as SendProbingMsg;
		
		interface Receive[uint8_t id];
		
		interface StdControl as RadioControl;
		interface RouteControl;
		
		interface StorageIf;
		
		interface CC2420Control;

#ifdef ULLA_STORAGE
    interface WriteToStorage;
#endif

#ifdef OSCOPE
    interface Oscope as ORFPower;
    interface Oscope as OLQI;
    interface Oscope as ORSSI;
#endif
  }

}

/* 
 *  Module Implementation
 */

implementation 
{
  enum {
    OSCOPE_DELAY = 10,
  };
  
  norace uint16_t rfpower, lqi, rssi /*, per */;
  norace uint8_t state;
  norace uint16_t numSamples;
  norace uint16_t timeInterval;
  norace uint8_t actionIndex;
  
  uint16_t count;
  uint32_t period;

  // module scoped variables
  TOS_MsgPtr msg;
  TOS_Msg buf;
  int8_t pending;
  QueryPtr query;
  ResultTuple rt;
  ResultTuplePtr rtp;

  /* task declaration */
  task void getRFPower();
  task void getLQI();
  task void getRSSI();
  //task void getPER();
  
  /* function declaration */
  //result_t addToResultTuple(ResultTuplePtr result);
  task void SimDataReady();

  //void CheckCounter();
  
  command result_t StdControl.init() {

  atomic {
    //state = HUMIDITY;
    rtp = &rt;
    actionIndex = 0;
    msg = &buf;
    count = 0;
    period = 0;
  }
    return (SUCCESS);
  }

/* start the sensorcontrol component */
  command result_t StdControl.start() {
		#if defined(ENABLE_ACK)
		//call CC2420Control.enableAutoAck();
		#endif
    call CC2420Control.SetRFPower(10);
    return SUCCESS;
  }

/* stop the sensorcontrol component */
  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }
#if 0
  // fill in the result tuple when dataReady, and signal receiveTuple
  // request from UQP
  command result_t RequestUpdate.execute(QueryPtr pq) {

    dbg(DBG_USR1, "Request update starts\n");
    atomic {
      query = pq;
      actionIndex = 0;
      state = pq->fields[actionIndex];
      numSamples = pq->nsamples;
      timeInterval = pq->interval;
      //rtp->qid = pq->qid;
      rtp->numFields = pq->numFields;
      rtp->numConds = pq->numConds;

    }

    call Timer.start( TIMER_ONE_SHOT, OSCOPE_DELAY );

    return SUCCESS;
  }
#endif
  task void getAttributeTask() {

    switch(state) {

      case RF_POWER:
      post getRFPower();
      break;

      case LQI:
      post getLQI();
      break;

      case RSSI:
      post getRSSI();
      break;

      /*
    case PER:
      post getPER();
      break; */
      case LED_ON:
	    call Leds.yellowOn();
	    break;
	    
      case LED_OFF:
	    call Leds.yellowOff();
	    break;

    //default:
    //  call Timer.start(TIMER_ONE_SHOT, 10);
    } // switch case
  }
  
  task void processNextAttribute() {
    dbg(DBG_USR1, "LLAM: processNextAttribute\n");
  }
  
  event result_t Timer.fired() {

    dbg(DBG_USR1, "Timer fired\n");
    // set a timeout in case a task post fails (rare)
    //call Timer.start(TIMER_ONE_SHOT, 100);
    post getAttributeTask();

    return SUCCESS;
  }
  
  // commands from UCP
  command result_t Control.execute(TOS_MsgPtr pmsg) {
    CommandMsgPtr cmd = (struct CommandMsg *) pmsg->data;

    switch (cmd->action) {

    case RF_POWER:
#ifndef MAKE_PC_PLATFORM
      call CC2420Control.SetRFPower(cmd->param);
#endif
    break;
    
    case TUNE_PRESET:
#ifndef MAKE_PC_PLATFORM
      call CC2420Control.TunePreset(cmd->param);
#endif
    break;
    
    case TUNE_MANUAL:
#ifndef MAKE_PC_PLATFORM
      call CC2420Control.TuneManual(cmd->param);
#endif
    break;

    }

    return SUCCESS;
  }
#if 0
  default event ResultTuplePtr RequestUpdate.receiveTuple(ResultTuplePtr rtr) {
    return rtr;
  } 
#endif  
  event result_t AttributeEvent.done(TOS_MsgPtr pmsg, result_t status) {
    return SUCCESS;
  }
 
  event result_t LinkEvent.done(TOS_MsgPtr pmsg, result_t status) {
  	return SUCCESS;
  }
  
  event result_t CompleteCmdEvent.done(TOS_MsgPtr pmsg, result_t status) {
  	return SUCCESS;
  }

/*------------------------------- Put data ------------------------------------*/

  task void putRFPower() {
#ifdef OSCOPE
    call ORFPower.put(rfpower);
#endif
    rtp->fields[actionIndex] = RF_POWER;
    rtp->data[actionIndex] = rfpower;
    //CheckCounter();
    post processNextAttribute();
  }

  task void putLQI() {
#ifdef OSCOPE
    call OLQI.put(lqi);
#endif
    rtp->fields[actionIndex] = LQI;
    rtp->data[actionIndex] = lqi;
    //CheckCounter();
    post processNextAttribute();
  }
  
  task void putRSSI() {
#ifdef OSCOPE
    call ORSSI.put(rssi);
#endif
    rtp->fields[actionIndex] = RSSI;
    rtp->data[actionIndex] = rssi;
    //CheckCounter();
    post processNextAttribute();
  }

  task void getRFPower() {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
#ifndef MAKE_PC_PLATFORM
    //rfpower = call CC2420Control.GetRFPower();
    //state = query->fields[actionIndex];
    //addToResultTuple(rtp);
    post putRFPower();
#else
    post SimDataReady();
#endif

  }

  task void getLQI() {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;

#ifndef MAKE_PC_PLATFORM
    lqi = msg->lqi;  // LQI
    post putLQI();
#else
    post SimDataReady();
#endif

  }
  
  task void getRSSI() {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;

#ifndef MAKE_PC_PLATFORM
    rssi = msg->strength;  // RSSI
    post putRSSI();
#else
    post SimDataReady();
#endif

  }
  
  command uint16_t LinkEstimation.calculatePER(TOS_MsgPtr pmsg) {
    uint16_t PER = 0;

    return PER;
  }

/*---------------------------- Link Provider Interface ------------------------*/

  task void continueUpdate() {
    call Timer.start(TIMER_REPEAT, period);
  }
  
  task void cancelUpdate() {
    call Timer.stop();
  }
  
  command uint8_t LinkProviderIf.execCmd[uint8_t id](CmdDescr_t* cmddescr) {
    struct ScanLinkMsg *scanlink;
    dbg(DBG_USR1, "LLAM: LP.execCmd\n");
    switch (cmddescr->cmd) {
      case SCAN_AVAILABLE_LINKS:
        dbg(DBG_USR1, "LLAM: ScanAvailableLinks\n");
        scanlink = (struct ScanLinkMsg *) buf.data;
        scanlink->parent = TOS_LOCAL_ADDRESS;
        scanlink->msg_type = SCAN_FORWARD_MSG;
        call SendScanLinks.send(msg, sizeof(struct ScanLinkMsg));
      break;
      
      default:
        //return COMMAND_NOT_SUPPORTED
      break;
    }
    return 1;
  }

  command uint8_t LinkProviderIf.requestUpdate[uint8_t id](RuId_t ruId, RuDescr_t* ruDescr, AttrDescr_t* attrDescr) {

    dbg(DBG_USR1, "LLAM: LPIf.requestUpdate\n");
    /*
     * 1. Start the timer
     * 2. signal events to UQP when the data is ready
     * 3. Check the counter
     */

    atomic {
      period = ruDescr->period;
      count = ruDescr->count;
    }
     
    post continueUpdate();
    
    return 1;
  }

  command uint8_t LinkProviderIf.cancelUpdate[uint8_t id](RuId_t ruId) {
    dbg(DBG_USR1, "LLAM: LPIf.cancelUpdate\n");
    return 1;
  }

	task void sendProbingMsgTask() {
	  //TOS_Msg beaconMsg; // can't be used locally here.
		FixedAttrMsg *fixed = (FixedAttrMsg *)msg->data;
		
		fixed->source = TOS_LOCAL_ADDRESS;
		fixed->type = 0; // request;
		//call Leds.redToggle();
		call SendProbingMsg.send(msg, sizeof(FixedAttrMsg));
	}
	
  // should be modified in order to get the attributes from the driver or
  // firmware not to probe everything. 2006/02/24
  // 2 kinds of queries
  // 1. remote queries - probing or reading from a firmware.
  // 2. local queries - reading attributes for a local.
  command uint8_t LinkProviderIf.getAttribute[uint8_t query_type](AttrDescr_t* attrDescr) {
    TOS_MsgPtr p;
    struct GetInfoMsg *getInfo = (struct GetInfoMsg *)buf.data;
		uint8_t *val_8;
		uint16_t *val_16;
    dbg(DBG_USR1, "LLAM: getAttribute\n");

    // 2006/03/06
    // LP has 2 mechanisms to deal with getAttribute() call
    // 1. Poll its neighbour because there is no update in the firmware
    // from any beacon signal
    // 2. Read from the firmware if there are periodic beacons sent from
    // its neighbour. It can cooperate with some other mechanism that provides
    // beacon, for example proactive routing agent.

    // LP should provide some mechanism to get info from neighbour (beacon?)
    // i.e. call SendBeacon();
		switch (attrDescr->attribute) {
			
			case LP_ID:
			
			break;
			
			case LINK_ID:
			case LQI:
			case RSSI:
				post sendProbingMsgTask();
				
			break;
			
			default:
			
			break;
		}
    return 1;
  }

  command uint8_t LinkProviderIf.setAttribute[uint8_t id](AttrDescr_t* attrDescr) {
    return 1;
  }

  command void LinkProviderIf.freeAttribute[uint8_t id](AttrDescr_t* attrDescr) {

  }

/*------------------------------- Transceiver ----------------------------------*/

  command uint8_t GetLinkInfo.getAttribute(TOS_Msg *tmsg) {
    struct GetInfoMsg *getinfo = (struct GetInfoMsg *)tmsg->data;

		dbg(DBG_USR1,"LLAM: GetLinkInfo.getAttribute\n");
    switch (getinfo->attribute) {
      case LQI:
      //call Leds.yellowToggle();
#ifndef MAKE_PC_PLATFORM
        getinfo->data = msg->lqi;
#endif
      break;

      case RSSI:
        dbg(DBG_USR1,"Get Me RSSI\n");
        //call Leds.redToggle();
        getinfo->attribute = RSSI;
        //getinfo->src_address = ;
        getinfo->data = 978;//msg->strength;

      break;

      case LINK_ID:
        getinfo->data = TOS_LOCAL_ADDRESS;
      break;

      case TYPE:
        getinfo->data = 9;//ULLA_MEDIATYPE_ZIGBEE;
      break;

      case STATE:
        getinfo->data = 11;
      break;

      case NETWORK_NAME:
        getinfo->data = 0x66;
      break;

      case RX_ENCRYPTION:
        getinfo->data = 1;
      break;

      case TX_ENCRYPTION:
        getinfo->data = 1;
      break;

      case MODE:
        getinfo->data = 1;//HALF_DUPLEX;
      break;

      default:
        dbg(DBG_USR1, "attribute not defined\n");
      break;
    }

    getinfo->linkid = TOS_LOCAL_ADDRESS;
    getinfo->type = 2;
    signal GetLinkInfo.getAttributeDone(tmsg);
    return 1;
  }
  
  event result_t SendScanLinks.sendDone(TOS_MsgPtr pmsg, result_t success) {
    AttrDescr_t* attrDescr;
    dbg(DBG_USR1, "LLAM: SendScanLinks.sendDone\n");
    //signal LinkProviderIf.getAttributeDone[REMOTE_QUERY](attrDescr);
    return success;
  }
	
	event result_t SendGetInfo.sendDone(TOS_MsgPtr pmsg, result_t success) {
    AttrDescr_t* attrDescr;
    dbg(DBG_USR1, "LLAM: SendGetInfo.sendDone\n");
    //signal LinkProviderIf.getAttributeDone[REMOTE_QUERY](attrDescr);
    return success;
  }
	
	event result_t SendProbingMsg.sendDone(TOS_MsgPtr pmsg, result_t success) {
    AttrDescr_t attrDescr;
    dbg(DBG_USR1, "LLAM: SendProbingMsg.sendDone\n");
		memcpy(&attrDescr, &(pmsg->data), sizeof(AttrDescr_t));
    ////////signal LinkProviderIf.getAttributeDone[REMOTE_QUERY](&attrDescr);
    return success;
  }

  event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr pmsg, void* payload, uint16_t payloadLen) {
    // receive GetInfo message from remote LP
    // should process and send the result back
    struct GetInfoMsg *getInfo = (struct GetInfoMsg *)pmsg->data;

    dbg(DBG_USR1, "LLAM: receive GetInfo message\n");
    return pmsg;
  }
/*------------------------------- Simulation Results ---------------------------*/
#ifdef MAKE_PC_PLATFORM

  task void SimDataReady() {

    dbg(DBG_USR1, "Simulate Data\n");
    switch(state) {

    case RF_POWER:
      dbg(DBG_USR1, "Simulate RF_POWER %d\n", actionIndex);
      rfpower = 16;
      post putRFPower();
      break;
      
    case LQI:
      dbg(DBG_USR1, "Simulate LQI %d\n", actionIndex);
      lqi = 17;
      post putLQI();
      break;
    case RSSI:
      dbg(DBG_USR1, "Simulate RSSI %d\n", actionIndex);
      rssi = 18;
      post putRSSI();
      break;
   }
  //post SimDataReady();
  }

#endif

/*------------------------------- ULLA Storage ---------------------------------*/
#ifdef ULLA_STORAGE
  event result_t WriteToStorage.writeDone(uint8_t *data, uint32_t bytes, result_t ok) {
    dbg(DBG_USR1,"WriteToStorage write done\n");
    return SUCCESS;
  }
#endif
  
} // end of implementation
