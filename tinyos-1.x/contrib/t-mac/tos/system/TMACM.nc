/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Original S-MAC Authors: Wei Ye, Honghui Chen
 * T-MAC modifications: Tom Parker
 *
 * This module implements Timeout-MAC (T-MAC)
 * http://www.consensus.tudelft.nl/documents_delft/03vandam.pdf 
 *
 * It has the following functions.
 *  1) Adaptive duty-cycle operation on radio -- periodic listen and sleep
 *  2) Broadcast only uses CSMA
 *  3) Many features for unicast
 *     - RTS/CTS for hidden terminal problem
 *     - fragmentation support for a long message
 *       A long message is divided (by upper layer) into multiple fragments.
 *       The RTS/CTS reserves the medium for the entire message.
 *       ACK is used for each fragment for immediate error recovery.
 *     - Node goes to sleep when its neighbors are talking to other nodes.
 */

/**
 * @author Wei Ye
 * @author Honghui Chen
 * @author Tom Parker
 */

#ifdef RECEIVE_ALWAYS

#ifndef DONT_REALLY_SLEEP
#define DONT_REALLY_SLEEP 1
#endif

#endif // RECEIVE_ALWAYS
 
includes PhyRadioMsg;
module TMACM
{
	provides
	{
		interface StdControl as MACControl;
		interface MACComm;
		interface MACTest;
		interface RadioTweak;
		interface RoutingHelpers;
	}
	uses
	{
		interface StdControl as PhyControl;
		interface RadioState;
		interface CarrierSense;
		interface PhyComm;
		interface Random;
		interface ClockMS as Clock;
		//interface TimeStamp;
		interface UARTDebug as Debug;
		interface RadioSettings;
		interface StdControl as ClockControl;
	}
}

implementation
{

#include "TMACMsg.h"
#include "PhyConst.h"
#include "TMACEvents.h"

//#define TMAC_PERFORMANCE

/* User-adjustable MAC parameters
 *--------------------------------
 * Default values can be overriden in each application's config.h
 * TMAC_MAX_NUM_NEIGHB: maximum number of neighbors.
 * TMAC_MAX_NUM_SCHED: maximum number of different schedules.
 * The following two macros define the period to search for new neighbors that
 * are potentially on a different schedules. The period is expressed as the
 * number of SYNC_PERIODs. Therefore, 30 means every 30 SYNC_PERIODs, the
 * node will keep listening for an entire SYNC_PERIOD. Max value: 255.
 * TMAC_SRCH_NBR_SHORT_PERIOD: if I have no neighbor, search more aggressively
 * TMAC_SRCH_NBR_LONG_PERIOD: used when I already have neighbors
 */

#ifndef TMAC_MAX_NUM_SCHED
#define TMAC_MAX_NUM_SCHED 6
#endif

#ifndef TMAC_SRCH_NBR_SHORT_PERIOD
#define TMAC_SRCH_NBR_SHORT_PERIOD 3
#endif

#ifndef TMAC_SRCH_NBR_LONG_PERIOD
#define TMAC_SRCH_NBR_LONG_PERIOD 30
#endif


/* MAC states
 * ----------
 * TMAC_SLEEP: radio is turned off, can't Tx or Rx
 * TMAC_IDLE: radio in idle mode, will go to Rx if start symbol is deteded.
 *   Can start Tx in this state
 * CARR_SENSE: carrier sense. Do it before initiate a Tx
 * TX_PKT: transmitting packet
 * RX_PKT: receiving some packet
 * BACKOFF - medium is busy, and cannot Tx
 * WAIT_CTS - just sent RTS, and is waiting for CTS
 * WAIT_DATA - just sent CTS, and is waiting for DATA
 * WAIT_ACK - just sent DATA, and is waiting for ACK
 */

	typedef enum
	{
		TMAC_SLEEP = 1,
		TMAC_IDLE,
		CARR_SENSE,
		TX_PKT,
		BACKOFF,
		RX_PKT,
		WAIT_CTS,
		WAIT_DATA,
		WAIT_ACK
	}__attribute__((packed))
	MACStates;

	// how to send a pkt
	typedef enum
	{ BCAST_DATA = 1, SEND_SYNC, SEND_RTS, SEND_CTS, SEND_DATA, SEND_ACK }  __attribute__((packed)) SendType;

	// data type definitions
	// note: pkt formats are defined in TMACMsg.h
	typedef struct
	{
		//bool active:1, inUse:1;			// flag indicating need to check numNodes
		bool active, inUse;			// flag indicating need to check numNodes
		int16_t counter;		// tick counter
	}__attribute__((packed))
	SchedTable;

	/*
	 * INIT_DONE = All init stuff done
	 * INIT_LISTEN = We're waiting to see if anyone else wants to give us a sync
	 * INIT_DIY = No sync seen, about to send our own
	 * INIT_GOT_BUT_WAIT = We saw a sync, but wait for others. Don't send out our own.
	 */

	typedef enum
	{ INIT_DONE = 0, INIT_LISTEN, INIT_DIY, INIT_GOT_BUT_WAIT }__attribute__((packed))
	InitStates;

	// state variables
	MACStates state;			// MAC state
	int16_t forceTime;			// MAC overrides state. 0 == normality
	//uint8_t numSched;			// number of different schedules
	SchedTable schedTab[TMAC_MAX_NUM_SCHED];	// schedule table
	bool txSync;				// flag to indicate we need to send a sync packet
	int16_t syncTime;			// time until next sync packet
	bool inMyFrame;				// flag to indicate we are in my frame, and therefore can send
	//uint8_t schedState;			// schedule state: first, second schedule...
	bool rxBusy;				// if we're currently receiving

	// timing variables
	uint16_t clockTime;			// clock time in milliseconds
	int16_t period;			// frame time
	uint8_t numSync;			// used for set/clear find neighbor flag
	uint16_t durDataPkt;		// duration (tx time needed) of data packet 
	uint16_t durCtrlPkt;		// duration (tx time needed) of control packet
	uint16_t durSyncPkt;		// duration (tx time needed) of sync packet
	uint16_t timeWaitCtrl;		// time to wait for a control packet
	uint16_t timeWaitData;		// time to wait for a ack packet in response to data
	int16_t geneTime;			// generic timer
	uint8_t schedCheckCounter;		// timer for track nodes activity in neighbor list
	uint8_t txReady;			    // we're got a packet queued to send internally in txReady ms
	uint8_t TATime;				// timer for adaptive listen
	int16_t timeTillSleep;		// timer for going back to sleep because nothing has happened
	InitStates init;			// are we in initial listen-only state?
	bool inClock;				// are we in clock.fire?
	uint16_t counter_missed;

	// Variables for Tx
	bool txRequest;				// if I have accept a tx request;
	SendType howToSend;			// what action to take for tx
	uint16_t sendAddr;			// node that I'm sending data to
	uint8_t dataSched;			// current schedule I'm talking to
	uint8_t syncSched;			// current schedule I'm talking to
	uint8_t numRetry;			// number of retries for a set of packets
	//uint8_t txFragsAll;			// number of fragments in this transmission
	//uint8_t txFragCount;		// number of transmitted fragments
	uint8_t txPktLen;			// length of data pkt to be transmitted
	MACHeader *dataPkt;			// pointer to tx data pkt, only access MAC header
	MACCtrlPkt ctrlPkt;			// MAC control packet
	MACSyncPkt syncPkt;			// MAC sync packet

	// Variables for Rx
	uint16_t recvAddr;			// node that I'm receiving data from
	//uint8_t lastRxFrag;			// fragment no of last received fragments
	bool enableSnoop; 			// do we send up *all* rx'ed DATA packets?

	uint16_t syncGap; 			// ms count between sync's
	bool rtscts; 				// enable/disable rtscts
	uint8_t maxRetries;			// max number of retries

	#ifdef TMAC_DEBUG
	// Debugging
	uint16_t rtsctsms; // time when we recieved RTS (to calculate RTS->CTS delay)
	#endif

/*#ifdef TMAC_PERFORMANCE
	char cntRadioTime;
	RadioTime radioTime;
#endif*/

	// function prototypes
	void updateSync(PhyPktBuf *packet, uint8_t durPkt);
	void handleRTS(PhyPktBuf *packet);
	void handleCTS(PhyPktBuf *packet);
	void *handleDATA(PhyPktBuf *packet, uint16_t rssi);
	void handleACK(PhyPktBuf *packet);
	void handleSYNC(PhyPktBuf *packet);
	void sendRTS();
	void sendCTS();
	void sendDATA();
	void sendACK();
	void sendSYNC();
	void runCarriersense();
	void resetSchedules();

	command result_t MACControl.init()
	{
		inClock = FALSE;

		// initialize constants
		durCtrlPkt = (PRE_PKT_BYTES + sizeof(MACCtrlPkt) * ENCODE_RATIO) * 8 / BANDWIDTH;
		durSyncPkt = (PRE_PKT_BYTES + sizeof(MACSyncPkt) * ENCODE_RATIO) * 8 / BANDWIDTH;
		durDataPkt = (PRE_PKT_BYTES + PHY_MAX_PKT_LEN * ENCODE_RATIO) * 8 / BANDWIDTH;

		// time to wait for CTS
		timeWaitCtrl = (PROC_DELAY + durCtrlPkt + PROC_DELAY);
		timeWaitData = (PROC_DELAY + durDataPkt + PROC_DELAY);

		TATime = 1.5* ((SLOTTIME*RTS_CONTEND*1.0)/BANDWIDTH + 2*timeWaitCtrl);
	
		// initialize state variables
		if (state == TMAC_IDLE)
			return SUCCESS;
		state = TMAC_IDLE;
		forceTime = 0;
		rtscts = TRUE;
		maxRetries = TMAC_RETRY_LIMIT;
		enableSnoop = FALSE;
		rxBusy = FALSE;

		period = PERIOD_LENGTH;
		syncGap = SYNC_PERIOD * PERIOD_LENGTH;
		
		resetSchedules();
		
		// initialize Tx variables
		txRequest = FALSE;

		// initialize UART debugging
		call Debug.init(7);
		call Debug.txState(TMAC_INIT_NODE);

		// initialize random number generator
		call Random.init();
		// initialize and start clock
		call ClockControl.init();

		//initialize physical layer
		call PhyControl.init();

		return SUCCESS;
	}

	void resetSchedules()
	{
		timeTillSleep = syncGap;	/* waiting for SYNC_PERIOD to start with guarantees we will
										 * have heard any possible neighbour schedules
										 */
		// initialize neighbor list
		schedCheckCounter = SCHED_CHECK_PERIODS;
		memset(schedTab, 0, sizeof(schedTab));

		// initialize timing variables
		clockTime = 0;
		txReady = 0;
		init = INIT_LISTEN;
		counter_missed = 0;

		// choose a tentative schedule, but don't broadcast until
		// listening for a whole SYNC_PERIOD.
		//schedState = 1;			// this is my first schedule

		//numSched = 1;
		syncTime = period; 
		//By default: schedTab[0].active = FALSE;
		//By default: schedTab[0].inUse = FALSE;
		schedTab[0].counter = period;
		txSync = FALSE;
		inMyFrame = FALSE;

		// Don't go to sleep for the first SYNC period.
		numSync = 1;
	}

	//~ /* refTime here has been already corrected for counter_missed */
	//~ inline void setMySched(MACSyncPkt *packet, uint16_t refTime)
	//~ {
		//~ // switch my schedule (first entry of schedule table)
		//~ // now only happens when the first neighbor is found
		//~ // follow the schedule in syncPkt
		//~ int16_t diff = (int16_t)schedTab[0].counter - (int16_t)refTime;
		//~ schedTab[0].counter = refTime;	//packet->sleepTime;
		//~ call Debug.tx16status(__SET_SCHED_0_COUNTER,refTime);
		//~ dbg(DBG_USR2,"Setting sched using %d\n",refTime);
		//~ if (diff > GUARDTIME && diff < -GUARDTIME)
		//~ {
			//~ // need to broadcast my schedule
			//~ syncTime = syncGap;
			//~ txSync = TRUE;
		//~ }
		//~ /*if (schedState==UCHAR_MAX)
			//~ schedState=1;
		//~ else
			//~ schedState++;*/
		//~ //start setting timer for update neighbor list
		//~ schedCheckCounter = SCHED_CHECK_PERIODS;
	//~ }

	//GPH: we may want to know whether there are other nodes on this schedule, and move
	// to another if we are the only one. For now, just leave it.
	//~ void checkMySched()
	//~ {
		//~ // check if I am the only one on schedTab[0]
		//~ // if yes, should switch and follow the next available schedule
		//~ // happens when an old node switches to a new schedule 
		//~ // and when I drop some inactive nodes from neighbor list(updating)
		//~ uint8_t i, schedId;
		//~ dbg(DBG_USR1,"Doing checkmysched\n");
		//~ schedId = 0;
		//~ if (schedTab[0].numNodes == 1 && numSched > 1 && numNeighb > 0)
		//~ {
			//~ for (i = 1; i < TMAC_MAX_NUM_SCHED; i++)
			//~ {
				//~ if (schedTab[i].numNodes > 0)
				//~ {				// switch to next available schedule
					//~ schedTab[0].counter = schedTab[i].counter;
					//~ schedTab[0].syncTime = syncGap;
					//~ schedTab[0].txSync = TRUE;
					//~ if (schedTab[0].txData == NEED_BCAST)
						//~ decrementNumBcast();
					//~ schedTab[0].txData = schedTab[i].txData;
					//~ schedTab[0].numNodes = schedTab[i].numNodes + 1;
					//~ // delete this schedule          
					//~ schedTab[i].numNodes = 0;
					//~ numSched--;
					//~ schedId = i;
					//~ break;
				//~ }
			//~ }
			//~ if (schedId > 0)
			//~ {
				//~ /*if (schedState==UCHAR_MAX)
					//~ schedState=1;
				//~ else
					//~ schedState++;*/
				//~ // update my neighbor list which relative to this schedId
				//~ for (i = 0; i < TMAC_MAX_NUM_NEIGHB; i++)
				//~ {
					//~ if (neighbList[i].nodeId!=TOS_BCAST_ADDR)
						//~ if (neighbList[i].schedId == schedId)
							//~ neighbList[i].schedId = 0;
				//~ }
			//~ }
		//~ }
	//~ }


	task void checkSchedList()
	{
		uint8_t i;
		for (i = 0; i < TMAC_MAX_NUM_SCHED; i++)
		{
			if (schedTab[i].inUse && !schedTab[i].active)
			{	// this schedule is not active recently
				schedTab[i].inUse = FALSE;
			}
			schedTab[i].active = FALSE;
		}
		if (!schedTab[0].inUse) {
			for (i = 1; i < TMAC_MAX_NUM_SCHED; i++)
			{
				if (schedTab[i].inUse)
				{
					memcpy(&schedTab[0],&schedTab[i],sizeof(SchedTable));
					schedTab[i].inUse = FALSE;
					break;
				}
			}
		}
		schedCheckCounter = SCHED_CHECK_PERIODS;
	}

	command result_t MACControl.start()
	{
		// fill in fixed portion of control packet
		ctrlPkt.fromAddr = TOS_LOCAL_ADDRESS;
		// fill in fixed portion of sync packet
		syncPkt.fromAddr = TOS_LOCAL_ADDRESS;
		syncPkt.type = SYNC_PKT;
		call Debug.start();
		call Debug.txStatus(_TMAC_STATE, state);
		return call ClockControl.start();
	}

	command result_t MACControl.stop()
	{
		return call ClockControl.stop();
	}


	void sleep()
	{
		// sleep mode
		/* don't go to sleep yet. reset TTS, clear init, and return*/
		if (init == INIT_LISTEN)
		{
			init = INIT_DIY;
			timeTillSleep = period;
			call Debug.txState(INIT_STATE_DIY);
			return;
		}
		/* if we've hit sleep, and we've gone into DIY mode, or we've already got a schedule, then mark this as done */
		if (init == INIT_DIY || init == INIT_GOT_BUT_WAIT)
		{
			call Debug.enable();
			init = INIT_DONE;
			call Debug.txState(INIT_STATE_DONE);
		}
		if (timeTillSleep >0) /* if we're not meant to go to sleep yet, don't! */
			return;
		if (forceTime>0)
		{
			dbg(DBG_ERROR,"We can't go to sleep yet!\n");
			return;
		}
		if (state == TMAC_IDLE)
		{
			bool ret = call RadioState.sleep();	// turn off the radio
			inMyFrame = FALSE;
			if (!ret)
			{
				call Debug.txState(RADIO_FAIL_SLEEP);
				return;
			}
			state = TMAC_SLEEP;
			call Debug.txStatus(_TMAC_STATE, state);
			call Debug.tx16status(__TMAC_CLOCK,schedTab[0].counter);
			signal MACTest.MACSleep();	// signal upper layer
			dbg(DBG_SIMRADIO,"%d: Sleep! (TTS=%d)\n",schedTab[0].counter, timeTillSleep);
		}
	}


	void wakeup()
	{
		// wake up from sleep, turn on radio and signal upper layer
		if (state != TMAC_SLEEP)
			return;
		dbg(DBG_SIMRADIO,"%d: Wakeup! \n",schedTab[0].counter);
		call RadioState.idle();	// turn on the radio
		state = TMAC_IDLE;
		call Debug.txStatus(_TMAC_STATE, state);
		signal MACTest.MACWakeup();	// signal upper layer
		if (timeTillSleep < TATime)
			timeTillSleep = TATime;
	}

	void resetTTS()
	{
		if (timeTillSleep>0)
			call Debug.tx16status(__RESET_TTS,timeTillSleep);
		/*else
			call Debug.tx16status(__RESET_TTS,0xFF00);*/
		if (timeTillSleep - (int16_t)counter_missed < TATime)
		{
			dbg(DBG_USR2,"Reset TTS to %d from %d\n",TATime,timeTillSleep);
			timeTillSleep = TATime+counter_missed;
		}
		dbg(DBG_USR2,"Attempted reset, TTS is now= %d\n",timeTillSleep);
		/*if (init == INIT_LISTEN && timeTillSleep>TATime)
		   timeTillSleep = TATime; */
		//call Debug.tx16status(__RESET_TTS,timeTillSleep);
	}

	void tryToSend()
	{
		// try to send a buffered packet
		if (state == TMAC_IDLE)
		{
			if (sendAddr == TOS_BCAST_ADDR)
				howToSend = BCAST_DATA;
			else
			{
				if (rtscts)
					howToSend = SEND_RTS;
				else
					howToSend = SEND_DATA;
			}
			txReady = 0; // don't do auto-send, wait for carrier-sense
			runCarriersense();
		}
		else
		{
			call Debug.txState(TRYTOSEND_FAIL_NOT_IDLE);
		}
		return;
	}

	//GPH: combine broadcastMsg and unicastMsg!!
	command result_t MACComm.broadcastMsg(void *data, uint8_t length)
	{
		bool killMe=FALSE;
		/* Just because we don't know any doesn't mean there aren't any
		 * We should still bcast on our own schedule anyways
		 */
		/*if (numNeighb == 0)
		{
			dbg(DBG_USR1,"Broadcast fail, because no neighbours!\n");
			return FAIL;
		}*/ 
		// Don't accept Tx request if I have already accepted a request
		if (data == 0 || length == 0 || length > PHY_MAX_PKT_LEN)
		{
			if (data == 0)
			{
				call Debug.txState(TMAC_BCAST_REQUEST_REJECTED_DATA_IS_0);
			}
			if (length == 0 || length > PHY_MAX_PKT_LEN)
			{
				call Debug.txState(TMAC_BCAST_REQUEST_REJECTED_PKTLEN_ERROR);
			}
			return FAIL;
		}
		// disable interrupt when check the value of txRequest
		atomic {
			if (txRequest == FALSE)
				txRequest = TRUE;
			else
			{
				call Debug.txState(TMAC_BCAST_REQUEST_REJECTED_TXREQUEST_IS_1);
				killMe = TRUE;
			}
		}
		if (killMe)
			return FAIL;
		dataPkt = (MACHeader *) data;
		txPktLen = length + sizeof(MACHeader);
		sendAddr = TOS_BCAST_ADDR;
		// fill in MAC header fields
		dataPkt->type = DATA_PKT;	// data pkt
		dataPkt->toAddr = TOS_BCAST_ADDR;
		dataPkt->fromAddr = TOS_LOCAL_ADDRESS;
		//dataPkt->duration = 0;
		//dataPkt->fragNo = 0;
		// set flag in each schedule
		return SUCCESS;
	}


	command result_t MACComm.unicastMsg(void *data, uint8_t length, uint16_t toAddr) //, uint8_t numFrags)
	{
		bool killMe=FALSE;
		// Don't accept Tx request if I have already accepted a request
		if (data == 0 || length == 0 || length > PHY_MAX_PKT_LEN) // || numFrags == 0)
		{
			if (data == 0)
			{
				call Debug.txState(TMAC_UCAST_REQUEST_REJECTED_DATA_IS_0);
			}
			if (length == 0 || length > PHY_MAX_PKT_LEN)
			{
				call Debug.txState(TMAC_UCAST_REQUEST_REJECTED_PKTLEN_ERROR);
			}
			/*if (numFrags == 0)
			{
				call Debug.txState(TMAC_UCAST_REQUEST_REJECTED_NUMFRAGS_IS_0);
			}*/
			return FAIL;
		}

		// disable interrupt when check the value of txRequest
		atomic {
			if (txRequest == FALSE)
				txRequest = TRUE;
			else
			{
				call Debug.txState(TMAC_UCAST_REQUEST_REJECTED_TXREQUEST_IS_1);
				killMe = TRUE;
			}
		}
		if (killMe)
			return FAIL;
		dataPkt = (MACHeader *) data;
		sendAddr = toAddr;
		txPktLen = length + sizeof(MACHeader);
		//txFragsAll = numFrags;
		//txFragCount = 0;
		numRetry = 0;
		// calculate duration of data packet/fragment
		durDataPkt = (PRE_PKT_BYTES + length * ENCODE_RATIO) * 8 / BANDWIDTH;
		// fill in MAC header fields except duration
		dataPkt->type = DATA_PKT;	// data pkt
		dataPkt->toAddr = sendAddr;
		dataPkt->fromAddr = TOS_LOCAL_ADDRESS;
		//dataPkt->fragNo = txFragCount;
		if (toAddr == TOS_LOCAL_ADDRESS)
		{
			signal MACComm.rxMsgDone(dataPkt,0);
			signal MACComm.unicastDone(dataPkt, TRUE);
			atomic txRequest = FALSE;
		}
		return SUCCESS;
	}


	/*command result_t MACComm.txNextFrag(void *data)
	{
		// Send subsequent fragments
		if (state != TX_NEXT_FRAG || data == 0 || forceState !=NORMAL_MAC)
			return FAIL;
		dataPkt = (MACHeader *) data;
		// fill in MAC header fields except duration
		dataPkt->type = DATA_PKT;	// data pkt
		dataPkt->toAddr = sendAddr;
		dataPkt->fromAddr = TOS_LOCAL_ADDRESS;
		//dataPkt->fragNo = txFragCount;
		// schedule to send this fragment
		call PhyComm.txPkt((uint8_t*)dataPkt, txPktLen);
		radioState = RADIO_TX;
		state = TX_PKT;
		call Debug.txStatus(_TMAC_STATE, state);
		howToSend = SEND_DATA;
		return SUCCESS;
	}*/

	//GPH: THIS IS A VERY DANGEROUS COMMAND!!! WE MAY BE SENDING THE CURRENT PACKET RIGHT NOW!!
	command result_t MACComm.txReset()
	{
		// force MAC to drop currently buffered tx packet
		// so that it will accept a new one
		txRequest = FALSE;
		return SUCCESS;
	}


	void txMsgDone(result_t success)
	{
		// prepare to tx next msg
		txRequest = FALSE;
		txReady = 0;
		state = TMAC_IDLE;
		call Debug.txStatus(_TMAC_STATE, state);
		#if defined(PLATFORM_PC) && !defined(NDEBUG)
		{
			RadioMsgSentEvent ev;
			memcpy(&ev.message, ((char *)dataPkt) + sizeof(MACHeader), sizeof(ev.message));
			ev.message.crc = 1; // Tools expect crc={0,1}, not actual CRC value -pal
			sendTossimEvent(NODE_NUM, AM_RADIOMSGSENTEVENT, tos_state.tos_time, &ev);
		}
		#endif
		signal MACComm.unicastDone(dataPkt, success);//, txFragCount);
	}

	event result_t PhyComm.txPktDone(PhyPktBuf *packet)
	{
		pktTypes pktType;
		if ((uint8_t*)packet != (uint8_t*)dataPkt && (uint8_t*)packet!=(uint8_t*)&ctrlPkt && (uint8_t*)packet!=(uint8_t*)&syncPkt)
		{
			dbg(DBG_ERROR,"Not one of my packets (pkt=%p, datapkt=%p, ctrlpkt=%p)\n",packet,dataPkt,&ctrlPkt);
			return signal MACComm.txRawDone((uint8_t*)packet);
		}
		geneTime = 0;
		if (packet == 0 || state != TX_PKT)
		{
			dbg(DBG_AM,"Failed to do txpktdone!\n");
			call Debug.txState(TRYTOSEND_FAIL_TXPKTDONE);
			call Debug.txStatus(_TMAC_STATE, state);
			return FAIL;		// CHECK if needed
		}
		pktType = packet->data[0];
		syncTime = syncGap;
		txSync = FALSE;
		//~ if (pktType>=FIRST_PKT_TYPE && pktType<=LAST_PKT_TYPE) /* we can sync on all, so reset */
		//~ {
			//~ schedTab[syncSched].txSync = FALSE;
			//~ schedTab[syncSched].syncTime = syncGap;
			//~ dbg(DBG_PACKET,"Sent sync'ed packet on sched %d (counter = %d)\n",syncSched,schedTab[0].counter);
		//~ }
		switch (pktType)
		{						// the type field
			case SYNC_PKT:
				dbg(DBG_PACKET,"Sent Sync packet on sched %d (counter = %d)\n",syncSched,schedTab[0].counter);
				state = TMAC_IDLE;
				call Debug.txStatus(_TMAC_STATE, state);
				call Debug.txState(TX_SYNC_DONE);
				break;
			case RTS_PKT:
				// just sent RTS, set timer for CTS timeout
				dbg(DBG_PACKET,"Sent RTS, waiting %d for CTS\n",timeWaitCtrl);
				state = WAIT_CTS;
				call Debug.txStatus(_TMAC_STATE, state);
				geneTime = timeWaitCtrl+counter_missed; // add counter_missed to avoid too early firing due to skipped clock.fire()'s
				call Debug.txState(TX_RTS_DONE);
				break;
			case CTS_PKT:			// just sent CTS
				state = WAIT_DATA;
				call Debug.txStatus(_TMAC_STATE, state);
				// wait for maximum length data packet time
				geneTime = timeWaitData+counter_missed; // add counter_missed to avoid too early firing due to skipped clock.fire()'s
				#ifdef TMAC_DEBUG
				call Debug.txStatus(_TX_CTS_DONE,clockTime-rtsctsms);
				#endif
				call Debug.txStatus(_TX_CTS_DONE,timeWaitCtrl);
				break;
			case DATA_PKT:
				if (((MACHeader *) packet)->toAddr == TOS_BCAST_ADDR)
				{
					txRequest = FALSE;
					signal MACComm.broadcastDone(dataPkt);
					txReady = 0;
					state = TMAC_IDLE;
					dbg(DBG_PACKET,"Sent Broadcast packet\n");
					call Debug.txState(TX_BCAST_DONE);
					#if defined(PLATFORM_PC) && !defined(NDEBUG)
 					{
						RadioMsgSentEvent ev;
						memcpy(&ev.message, ((char *)packet) + sizeof(MACHeader), sizeof(ev.message));
						ev.message.crc = 1; // Tools expect crc={0,1}, not actual CRC value -pal
						sendTossimEvent(NODE_NUM, AM_RADIOMSGSENTEVENT, tos_state.tos_time, &ev);
					}
					#endif
				}
				else
				{					// unicast is done
					dbg(DBG_PACKET,"Sent Unicast packet. Waiting %d for ACK\n",timeWaitCtrl);
					state = WAIT_ACK;
					call Debug.txStatus(_TMAC_STATE, state);
					// waiting for ACK, set timer for ACK timeout
					geneTime = timeWaitCtrl+counter_missed; // add counter_missed to avoid too early firing due to skipped clock.fire()'s
					call Debug.txState(TX_UCAST_DONE);
				}
				break;
			case ACK_PKT:
				state = TMAC_IDLE;
				call Debug.txStatus(_TMAC_STATE, state);
				call Debug.txState(TX_ACK_DONE);
				break;
			default:
				dbg(DBG_PACKET,"Sent some unknown packet type (%d)!\n",pktType);
				break;
		}
		call RadioState.idle();	// Idle the radio
		resetTTS();
		dbg(DBG_PACKET,"%d: packet done\n",clockTime);
		return SUCCESS;
	}

	void tryToResend()
	{
		txReady = 1;
		state = TMAC_IDLE;
		call Debug.txStatus(_TMAC_STATE, state);
		call Debug.txStatus(_TX_RESEND,numRetry);
		// try to re-send a packet when CTS or ACK timeout
		if (numRetry < maxRetries)
		{
			numRetry++;
			// wait until receiver's next wake-up time
			//sleep();
		}
		else
		{
			dbg(DBG_PACKET,"RTS send failed, giving up\n");
			call Debug.txState(TX_RESEND_LIMIT);
			// reached retry limit, give up Tx
			txMsgDone(FAIL);		// with txFragCount < txFragsAll;
		}
	}

	void runCarriersense()
	{
		uint16_t backoffSlots, listenBits;
		backoffSlots = (call Random.rand() & (uint16_t) RTS_CONTEND)+1;
		listenBits = SLOTTIME * backoffSlots;
		if (listenBits<=0)
			listenBits = SLOTTIME;
		// start carrier sense and change state needs to be atomic
		// to prevent start symbol is detected between them
		dbg(DBG_USR1,"carrier sense bits = %d %d %d\n",listenBits, SLOTTIME, backoffSlots);
		atomic {
			if (call CarrierSense.start(listenBits) == SUCCESS)
			{
				state = CARR_SENSE;
				call Debug.txStatus(_TMAC_STATE, state);
			}
		}
		resetTTS();
	}

	event void Clock.fire(uint16_t counter_inc)
	{
		// handle clock event
		uint8_t i;
		uint16_t time_to_next_event=0;
		//call Debug.tx16status(__TMAC_CLOCK,counter_inc);
		/*#if defined(PLATFORM_PC) && !defined(NDEBUG)
		if (counter_inc!=1)
			dbg(DBG_ERROR,"Clock increment = %d\n",counter_inc);
		#endif*/
		// advance clock
		clockTime+=counter_inc;

		if (init == INIT_DONE)
			dbg(DBG_CLOCK, "Clock time = %d (state = %d)\n", clockTime,state);
		{
			bool killme = FALSE;
			atomic 
			{
				if (inClock || (state == TX_PKT && txReady==0) || state == RX_PKT || rxBusy)
				{
					counter_missed += counter_inc;
					killme = TRUE;
				}
				else
				{
					inClock = TRUE;
					counter_inc += counter_missed;
					counter_missed = 0;
				}
			}
			if (killme)
			{
				//call Debug.tx16status(__COUNTER_MISSED,counter_missed);
				return;
			}
		}

		// check force
		if (forceTime>0)
		{
			forceTime-=counter_inc;
			if (forceTime <= 0)
				call RoutingHelpers.endForce();
		}

		// generic timer
		if (geneTime > 0)
		{
			geneTime-=counter_inc;
			if (geneTime <= 0)
			{
				if (state == RX_PKT || rxBusy)
					geneTime =1;
				else
				{
					switch (state)
					{
						case BACKOFF:
							call Debug.txState(TIMER_FIRE_BACKOFF);
							// other node should be done
							state = TMAC_IDLE;
							call Debug.txStatus(_TMAC_STATE, state);
							break;
							
						case WAIT_CTS: // cts reply to our rts not seen
							call Debug.txState(TIMER_FIRE_WAIT_CTS);
							dbg(DBG_PACKET, "%d: Try to resend RTS (numretry=%d)\n",clockTime,numRetry);
							tryToResend();
							break;

						case WAIT_DATA: // Data never turned up after CTS xmit
							call Debug.txState(TIMER_FIRE_WAIT_DATA);
							state = TMAC_IDLE;
							call Debug.txStatus(_TMAC_STATE, state);
							break;
						
						case WAIT_ACK: // ACK timeout
							call Debug.txState(TIMER_FIRE_WAIT_ACK);
							dbg(DBG_PACKET, "%d: ACK Failed, retrying (numretry=%d)\n",clockTime,numRetry);
							tryToResend();
							break;

						// These states don't use geneTime, so ignore
						case TMAC_SLEEP:
						case TMAC_IDLE:
						case CARR_SENSE:
						case TX_PKT:
						case RX_PKT:
						//case TX_NEXT_FRAG:
							//dbg(DBG_ERROR, "genTime timed out in state %d\n",state);
							break;
					}
				}
			}
		}
		timeTillSleep-=counter_inc;
		// update status of each schedule and arrange tx if needed
		for (i = 0; i < TMAC_MAX_NUM_SCHED; i++)
		{
			if (schedTab[i].inUse || i == 0)
			{
				//~ #if defined(PLATFORM_PC) && !defined(NDEBUG)
				//~ if (init == INIT_DONE || counter_inc>1)
				//~ {
					//~ dbg(DBG_CLOCK, "Schedule number %d, count = %d, TTS=%d, state=%d, init=%d, txSync/Data = %d/%d\n", i, schedTab[i].counter, timeTillSleep, state, init, schedTab[i].txSync, schedTab[i].txData);
					//~ //call Debug.tx16status(__TMAC_CLOCK,schedTab[i].counter);
				//~ }
				//~ #endif
				//if (state == WAIT_CTS || txReady)
				if (schedTab[i].counter > TATime && (schedTab[i].counter-(int16_t)counter_inc)<=TATime)
				{
					//Need to know that my frame has started
					if (i == 0)
						inMyFrame = TRUE;
					//GPH: ugly case here: when two schedules start to overlap, we don't reset the inMyFrame flag once we pass the original timeTillSleep
					//	For now, let's just hope the other nodes know this schedule as well.
					if (state == TMAC_SLEEP)
						wakeup();	// wake up to tx
					resetTTS();
					call Debug.txState(TIMER_FIRE_LISTEN_DATA);
					call Debug.txStatus(_TMAC_STATE, state);
				}
				schedTab[i].counter-= counter_inc;
				if (schedTab[i].counter <= 0)
				{
					schedTab[i].counter += period;
				}
				if (schedTab[i].counter>(int16_t)TATime && (time_to_next_event==0||time_to_next_event> schedTab[i].counter-(int16_t)TATime))
				{
					//dbg(DBG_ERROR,
					time_to_next_event = schedTab[i].counter-(int16_t)TATime;
				}
			}
		}
		syncTime-=counter_inc;
		if (syncTime <= 0)
		{
			txSync = TRUE;
			call Debug.txState(TIMER_FIRE_NEED_TX_SYNC);
			//reset timer immediately to keep dependent timers running
			syncTime += syncGap;
			numSync--;	// for neighbor discovery
			if (numSync <= 0)
			{
				timeTillSleep = syncGap; /* stay awake for a whole syncGap to find others */
				//~ dbg(DBG_USR1, "Searching for neighbours (num neigh=%d)\n",numNeighb);
				if (!schedTab[0].inUse)
				{	// reset neighbor discovery timer
					numSync = TMAC_SRCH_NBR_SHORT_PERIOD;
				}
				else
				{
					numSync = TMAC_SRCH_NBR_LONG_PERIOD;
				}
			}
			if (schedCheckCounter > 0)
			{
				schedCheckCounter--;
				if (schedCheckCounter == 0)
				{	// time to update my neighbor list
					if (!post checkSchedList())
						schedCheckCounter = 1;
				}
			}
		}
		if (inMyFrame && state == TMAC_IDLE)
		{
			if (txRequest && init == INIT_DONE) {
				dbg(DBG_AM, "Time to send data... TTS=%d\n",timeTillSleep);
				// schedule sending of data
				//call Debug.txStatus(_TIMER_FIRE_NEED_TX_DATA,schedTab[i].txData);
				tryToSend();
			} else if (txSync && ((init == INIT_DIY || init == INIT_DONE))) {
				howToSend = SEND_SYNC;
				call Debug.txState(TMAC_SEND_SYNC_NOW);
				runCarriersense();	
			}
		}
		
		if (timeTillSleep <= 0 && state == TMAC_IDLE)
		{
			call Debug.txStatus(_TIMER_FIRE_SCHED_SLEEP,-timeTillSleep<254?-timeTillSleep:254);
			sleep();	// sleep if I'm idle
		}

		// tx delay timer
		if (txReady>0)
		{
			// As this only happens while we're waiting just before we send a packet
			// we are always decrementing just by one. We shouldn't even do bigWait
			// microjumps here (e.g. during tx/rx) so we can safely leave this alone.
			txReady--;
			if (txReady == 0 && state == TX_PKT)
			{
				call Debug.txStatus(_TIMER_FIRE_TX_DELAY, howToSend);
				switch(howToSend)
				{
					case SEND_CTS:
						sendCTS();
						break;
						
					case SEND_DATA:
						sendDATA();
						break;

					case SEND_ACK:
						sendACK();
						break;

					case SEND_RTS:
					case SEND_SYNC:
					case BCAST_DATA:
						call Debug.txState(WAIT_FOR_BAD_SEND);
						break;
				}
			}
		}

#ifndef RECEIVE_ALWAYS
		// try to put CPU into idle mode
		if (state == TMAC_SLEEP && time_to_next_event > 1)
		{
			call Clock.BigWait(time_to_next_event);
			call Debug.tx16status(__BIGWAIT,time_to_next_event);
		}
#endif		

		atomic inClock = FALSE;
	}


	event result_t CarrierSense.channelBusy()
	{
		// physical carrier sense indicate channel busy
		// Do nothing and stay in idle to receive a packet
		// Will sleep at my next sleep time if can't get a packet
		dbg(DBG_AM,"Channel busy detected\n");
		if (forceTime>0)
			signal RoutingHelpers.noSleepDone(FAIL);
		if (state == CARR_SENSE)
		{
			state = TMAC_IDLE;
			call Debug.txStatus(_TMAC_STATE, state);
		}
		return SUCCESS;
	}


	event result_t CarrierSense.channelIdle()
	{
		// physical carrier sense indicate channel idle
		// start sending
		if (forceTime>0)
		{
			signal RoutingHelpers.noSleepDone(SUCCESS);
			return SUCCESS;
		}
		if (state != CARR_SENSE)
			return FAIL;
		dbg(DBG_AM,"Channel idle detected\n");

		switch(howToSend)
		{
			case SEND_SYNC:
				sendSYNC();
				break;

			case SEND_RTS:
				sendRTS();
				break;
				
			case BCAST_DATA:
			case SEND_DATA:
				sendDATA();
				break;

			/* these don't use carrier sense, so ignore */
			case SEND_CTS:
			case SEND_ACK:
				break;
		}

		return SUCCESS;
	}

	event result_t PhyComm.startSymDetected(PhyPktBuf *pkt)
	{
		call Debug.tx16status(__TMAC_CLOCK,schedTab[0].counter);
		dbg(DBG_AM, "TMAC saw start symbol\n");
		rxBusy = TRUE;
		// put in coarse time stamp in ms
		pkt->info.timeCoarse = clockTime;
		
		// TX_PKT only happens here while we're doing a txReady pause before sending
		if (state == TMAC_IDLE || state == CARR_SENSE || state == BACKOFF || state == TX_PKT)
		{
			state = RX_PKT;
			call Debug.txStatus(_TMAC_STATE, state);
			geneTime = 0;
		}
		else
			call Debug.txStatus(_TMAC_STATE, state);
		return SUCCESS;
	}


	void handleErrPkt()
	{
		call Debug.txState(HANDLE_ERR_PKT);
		state = TMAC_IDLE;
		call Debug.txStatus(_TMAC_STATE, state);
	}


	event PhyPktBuf *PhyComm.rxPktDone(PhyPktBuf *packet, uint16_t error, uint16_t rssi)
	{
		pktTypes pktType;
		PhyPktBuf *ret = packet;

#ifndef RECEIVE_ALWAYS
		if (state == TMAC_SLEEP)
		{
			dbg(DBG_PACKET, "We're asleep, so discard!\n");
			call Debug.tx16status(__RADIO_FAIL_SLEEP,schedTab[0].counter);
			goto end_rxpktdone;		// if in sleep, reject any pkt. A bug occurs!
		}
#endif		
		resetTTS();
		if (error!=0)
		{						// if received an erroneous pkt, a sign of collision
			call Debug.tx16status(__RX_ERROR,error);
			handleErrPkt();
			goto end_rxpktdone;
		}
		pktType = packet->data[0];
		// dispatch to actual packet handlers
		
		switch (pktType)
		{
			case DATA_PKT:
				dbg(DBG_PACKET, "%d: Recieved a DATA packet\n", clockTime);
				ret = handleDATA(packet, rssi);
				break;

			case RTS_PKT:
				dbg(DBG_PACKET, "%d: Recieved an RTS packet\n", clockTime);
				call Debug.txState(RX_RTS_DONE);
				handleRTS(packet);
				break;

			case CTS_PKT:
				dbg(DBG_PACKET, "%d: Recieved a CTS packet\n", clockTime);
				call Debug.txState(RX_CTS_DONE);
				handleCTS(packet);
				break;

			case ACK_PKT:
				dbg(DBG_PACKET, "%d: Recieved an ACK packet\n", clockTime);
				call Debug.txState(RX_ACK_DONE);
				handleACK(packet);
				break;

			case SYNC_PKT:
				dbg(DBG_PACKET, "%d: Recieved a SYNC packet\n", clockTime);
				call Debug.txState(RX_SYNC_DONE);
				handleSYNC(packet);
				break;

			default:
				dbg(DBG_PACKET, "%d: Recieved a WEIRD packet (%d)!\n", clockTime,pktType);
				call Debug.txStatus(_RX_UNKNOWN_PKT,pktType);
				handleErrPkt();
				ret = signal MACComm.rxWeirdDone(packet,rssi);
				break;
		}
		end_rxpktdone:
		rxBusy = FALSE;
		return ret;
	}


	void handleRTS(PhyPktBuf *pkt)
	{
		// internal handler for RTS
		MACCtrlPkt *packet;
		packet = (MACCtrlPkt *) pkt;
		if (packet->toAddr == TOS_LOCAL_ADDRESS)
		{
			recvAddr = packet->fromAddr;	// remember sender's address
			//lastRxFrag = 250;
			// schedule sending CTS
			state = TX_PKT;
			call Debug.txStatus(_TMAC_STATE, state);
			howToSend = SEND_CTS;
         	txReady = 4; /* send ASAP */
			ctrlPkt.duration = packet->duration-(PROC_DELAY+durCtrlPkt); // time for everything *except* what we're going to do (CTS)
			dbg(DBG_PACKET,"RTS recieved for me, send off a CTS\n");
			#ifdef TMAC_DEBUG
			rtsctsms = clockTime;
			#endif
		}
		else
		{	// packet destined to another node
			dbg(DBG_PACKET,"RTS destined for another node (%d)\n",packet->toAddr);
			// keep listening until confirm sender gets a CTS or starts tx data
			call Debug.txStatus(_RTS_NOT_FOR_ME, packet->toAddr);
			state = BACKOFF;	// wait for a CTS, and then the data
			geneTime = timeWaitCtrl*2+counter_missed; // add counter_missed to avoid too early firing due to skipped clock.fire()'s
			call Debug.txStatus(_TMAC_STATE, state);
		}
		updateSync(pkt, durCtrlPkt);
	}


	void handleCTS(PhyPktBuf *pkt)
	{
		// internal handler for CTS
		MACCtrlPkt *packet;
		packet = (MACCtrlPkt *) pkt;
		if (packet->toAddr == TOS_LOCAL_ADDRESS)
		{
			dbg(DBG_PACKET,"Handled CTS from %d (sendAddr = %d)\n",packet->fromAddr,sendAddr);
			if (state == WAIT_CTS && packet->fromAddr == sendAddr)
			{
				// cancel CTS timer
				geneTime = 0;
				// schedule sending DATA
				state = TX_PKT;
				call Debug.txStatus(_TMAC_STATE, state);
				howToSend = SEND_DATA;
            	txReady = 4;
			}
			else
				handleErrPkt();
		}
		else
		{						// packet destined to another node
			geneTime = packet->duration+counter_missed; // add counter_missed to avoid too early firing due to skipped clock.fire()'s
			state = BACKOFF;
			call Debug.txStatus(_TMAC_STATE, state);
		}
		updateSync(pkt,durCtrlPkt);
	}


	void *handleDATA(PhyPktBuf *pkt, uint16_t rssi)
	{
		// internal handler for DATA packet
		MACHeader *packet = (MACHeader *) pkt;
		void *ret = NULL;

		if (packet->toAddr == TOS_BCAST_ADDR)
		{						// broadcast packet
			dbg(DBG_PACKET, "Got a broadcast packet\n");
			call Debug.txState(RX_BCAST_DONE);
			state = TMAC_IDLE;
			call Debug.txStatus(_TMAC_STATE, state);
		}
		else if (packet->toAddr == TOS_LOCAL_ADDRESS)
		{						// unicast packet
			// could receive data in rx_pkt or  wait_data state
			call Debug.txState(RX_UCAST_DONE);
			if ((state == WAIT_DATA && packet->fromAddr == recvAddr) || state == RX_PKT)
			{
				dbg(DBG_PACKET, "Got a unicast packet for me\n");
				// schedule sending ACK
				state = TX_PKT;
				call Debug.txStatus(_TMAC_STATE, state);
				howToSend = SEND_ACK;
            	txReady = 4;
			} else {
				handleErrPkt();
			}
		}
		else
		{
			//GPH: Here is an error in all current T-MAC implementations !!!
			dbg(DBG_PACKET, "Got a unicast packet for someone else (%d)\n",packet->toAddr);
			geneTime = PROC_DELAY + durCtrlPkt + counter_missed;
			state = BACKOFF;
			call Debug.txStatus(_TMAC_STATE, state);
		}
		
		// we need to give this to upper layers irregardless of who it's for
		// they do the filtering
		ret = signal MACComm.rxMsgDone(packet,rssi); 
		
		updateSync(pkt, (PRE_PKT_BYTES + pkt->length * ENCODE_RATIO) * 8.0 / BANDWIDTH);
		return ret;
	}

	void handleACK(PhyPktBuf *pkt)
	{
		// internal handler for ACK packet
		MACCtrlPkt *packet;
		packet = (MACCtrlPkt *) pkt;
		if (packet->toAddr == TOS_LOCAL_ADDRESS)
		{
			if (state == WAIT_ACK && packet->fromAddr == sendAddr)
			{
				// cancel ACK timer
				geneTime = 0;
				txMsgDone(SUCCESS);
			}
			else
				handleErrPkt();
		}
		else
		{						// packet destined to another node
			state = TMAC_IDLE;
			call Debug.txStatus(_TMAC_STATE, state);
		}
		updateSync(pkt, durCtrlPkt);
	}


	void handleSYNC(PhyPktBuf *pkt)
	{
		// if we receive a sync pkt, go back to idle
		state = TMAC_IDLE;
		call Debug.txStatus(_TMAC_STATE, state);
		updateSync(pkt, durSyncPkt);
	}
	
	void updateSync(PhyPktBuf *pkt, uint8_t durPkt)
	{
		uint8_t i;
		uint16_t refTime;
		uint8_t rxDelay;
		MACSyncPkt* packet = (MACSyncPkt*)pkt;
		/*if (packet->state == 0) // invalid, so skip
			return;*/

		// calculate Rx delay of packet
		// adjust TX_TRANSITION_TIME to make rxDelay calculated correctly
		rxDelay = (clockTime - pkt->info.timeCoarse) + (PRE_PKT_BYTES * 8 / BANDWIDTH) + TX_TRANSITION_TIME;
		// sanity check
		dbg(DBG_PACKET,"Sync testing. rxDelay=%d durPkt=%d\n",rxDelay,durPkt);
		if (((int)rxDelay - durPkt) < -2 || rxDelay>durPkt+(PROC_DELAY*2))
		{
			call Debug.txStatus(_SYNC_SANITY_FAIL,clockTime - pkt->info.timeCoarse);
			call Debug.txStatus(_SYNC_SANITY_FAIL,rxDelay);
			call Debug.txStatus(_SYNC_SANITY_FAIL,durPkt);
			call Debug.txStatus(_SYNC_SANITY_FAIL,pkt->length);
			dbg(DBG_ERROR,"Sync sanity failed. rxDelay=%d durPkt=%d\n",rxDelay,durPkt);
			return;
		}

		call Debug.tx16status(__RX_DELAY,rxDelay);
		refTime = (packet->sleepTime < rxDelay ? period : 0) + packet->sleepTime - rxDelay;
		if (refTime>period) // too big, discard
		{
			call Debug.tx16status(__EXCESSIVE_REFTIME,refTime);
			return;
		}
		dbg(DBG_SCHED,"Sleeptime = %d, rxDelay = %d, refTime = %d\n",packet->sleepTime,rxDelay,refTime);
		call Debug.tx16status(__PACKET_SLEEPTIME,packet->sleepTime);
//		call Debug.txStatus(_NUM_NEIGHBOURS,numNeighb);

		//If we don't have a neighbour yet, it will automatically pick schedule 0 for it. So we will
		//always have a neighbour in our schedule after this.
		for (i = 0; i < TMAC_MAX_NUM_SCHED; i++)
		{
			if (schedTab[i].inUse)
			{
				int16_t timeDiff = (int16_t)refTime - ((int16_t)schedTab[i].counter - (int16_t)counter_missed);
				if (timeDiff < (GUARDTIME-period))
					timeDiff += period;
				else if (timeDiff > (period-GUARDTIME))
					timeDiff -= period;
				dbg(DBG_PACKET,"timeDiff = %d, GUARDTIME=%d\n",timeDiff,GUARDTIME);
				if (timeDiff > -GUARDTIME && timeDiff < GUARDTIME)
				{
					dbg(DBG_PACKET,"Picked schedule %d (counter=%d)\n",i,schedTab[i].counter);
					schedTab[i].counter += timeDiff/2;	// packet->sleepTime;
					schedTab[i].active = TRUE;
					call Debug.tx16status(__SCHED_UPD_SCHED,timeDiff);
					call Debug.tx16status(__SCHED_UPD_SCHED,refTime);
					break;
				}
				else
					dbg(DBG_PACKET,"*Not* picking schedule %d (counter=%d)\n",i,schedTab[i].counter);
			}
		}
		if (i == TMAC_MAX_NUM_SCHED)
		{						// unknown schedule
			// add an entry to the schedule table
			for (i = 0; i < TMAC_MAX_NUM_SCHED; i++)
			{
				if (!schedTab[i].inUse)
				{			// found an empty entry
					dbg(DBG_PACKET,"New schedule created %d (refTime=%d)\n",i,refTime);
					schedTab[i].counter = refTime + counter_missed;	//packet->sleepTime;
					schedTab[i].inUse = TRUE;
					schedTab[i].active = TRUE;
					call Debug.txStatus(_SCHED_NEW_ID,i);
					call Debug.tx16status(__SCHED_NEW_SCHED,refTime+counter_missed);
					call Debug.tx16status(__SCHED_NEW_SCHED,(int16_t)schedTab[0].counter);
					call Debug.tx16status(__COUNTER_MISSED,counter_missed);
					break;
				}
			}
		}
	}

	void setupPkt(MACSyncPkt* pkt,pktTypes type)
	{
		// MACSyncPkt is the basic type here because it's the simplest packet, 
		// with a BASIC_HEADER at the beginning and a crc at the end. All other 
		// packets should follow that design.
		dbg(DBG_PACKET,"Setting up packet with counter %d and type %d. fromaddr=%d\n",schedTab[0].counter,/*schedState,*/type,pkt->fromAddr);
		atomic pkt->sleepTime = schedTab[0].counter;
		//pkt->state = schedState;
		pkt->type = type;
	}

	void sendRTS()
	{
		// construct and send RTS packet
		setupPkt((MACSyncPkt*)&ctrlPkt,RTS_PKT);
		ctrlPkt.toAddr = sendAddr;
		// reserve time for CTS + DATA + ACK
		ctrlPkt.duration = timeWaitCtrl * 2 + durDataPkt + PROC_DELAY;
		// send RTS
		call PhyComm.txPkt((PhyPktBuf*)&ctrlPkt, sizeof(ctrlPkt));
		state = TX_PKT;
		call Debug.txStatus(_TMAC_STATE, state);
	}


	void sendCTS()
	{
		// construct and send CTS
		setupPkt((MACSyncPkt*)&ctrlPkt,CTS_PKT);
		ctrlPkt.toAddr = recvAddr;
		// send CTS
		call PhyComm.txPkt((PhyPktBuf*)&ctrlPkt, sizeof(ctrlPkt));
		state = TX_PKT;
		call Debug.txStatus(_TMAC_STATE, state);
	}

	void sendDATA()
	{
		// send a unicast data packet
		// assume all MAC header fields have been filled except the duration
		dbg(DBG_PACKET, "Sending Data packet (len=%d)\n",txPktLen);
		setupPkt((MACSyncPkt*)dataPkt,DATA_PKT);
		call PhyComm.txPkt((PhyPktBuf*)dataPkt, txPktLen);
		state = TX_PKT;
		call Debug.txStatus(_TMAC_STATE, state);
	}

	void sendACK()
	{
		// construct and send ACK
		setupPkt((MACSyncPkt*)&ctrlPkt,ACK_PKT);
		ctrlPkt.toAddr = recvAddr;
		call PhyComm.txPkt((PhyPktBuf*)&ctrlPkt, sizeof(ctrlPkt));
		state = TX_PKT;
		call Debug.txStatus(_TMAC_STATE, state);
	}

	void sendSYNC()
	{
		dbg(DBG_PACKET,"Sending a sync packet using counter %d\n",schedTab[0].counter);
		// construct and send SYNC packet
		setupPkt(&syncPkt,SYNC_PKT);
		call PhyComm.txPkt((PhyPktBuf*)&syncPkt, sizeof(syncPkt));
		state = TX_PKT;
		call Debug.txStatus(_TMAC_STATE, state);
	}

	command result_t RadioTweak.enableRTSCTS(bool enable)
	{
		rtscts = enable;
		return SUCCESS;
	}

	command result_t RadioTweak.setSyncInterval(uint16_t syncint)
	{
		syncGap = period * syncint;
		resetSchedules();
		return SUCCESS;
	}

	command result_t RadioTweak.setPeriodLength(uint16_t periodlen)
	{
		period = periodlen;
		resetSchedules();
		return SUCCESS;
	}

	command result_t RadioTweak.setMaxRetries(uint8_t limit)
	{
		maxRetries = limit;
		return SUCCESS;
	}

	command result_t RadioTweak.setSnoop(bool enable)
	{
		enableSnoop = enable;
		return SUCCESS;
	}

	command result_t RadioTweak.SetRFPower(uint8_t power)
	{
		return call RadioSettings.SetRFPower(power);
	}

	// default do-nothing handler for MACTest interface
	default event void MACTest.MACSleep()
	{
	}


	default event void MACTest.MACWakeup()
	{
	}

	command uint16_t* RoutingHelpers.getNeighbours()
	{
		/* uint16_t *ret = (uint16_t*)malloc((numNeighb+1)*sizeof(uint16_t));
		uint8_t i;
		for (i=0;i<numNeighb;i++)
			ret[i] = neighbList[i].nodeId;
		ret[numNeighb] = 0;
		return ret; */
		return 0;
	}
	
	command uint8_t RoutingHelpers.sendTime(uint8_t length)
	{
		return (PRE_PKT_BYTES + (length+OFFSET(struct TOS_Msg,data)+1+2) * ENCODE_RATIO) * 8 / BANDWIDTH;
	}

	command result_t RoutingHelpers.forceNoSleep(uint16_t msec, bool forReply)
	{
		if (state != TMAC_IDLE && (!forReply || state!=BACKOFF) && state!=CARR_SENSE)
		{
			dbg(DBG_ERROR,"Awake failed, TMAC state = %d\n",state);
			return FAIL;
		}
		if (msec>forceTime)
		{
			forceTime = msec;
			dbg(DBG_ERROR,"Trying to stay awake for the next %d msec\n",msec);
			if (state == TMAC_SLEEP)
				wakeup();
			runCarriersense();
		}
		return SUCCESS;
	}


	command result_t RoutingHelpers.endForce()
	{
		forceTime = 0;
		signal RoutingHelpers.forceComplete();
		/*if (state == TMAC_SLEEP)
			sleep();
		else*/
			wakeup();
		if (state == BACKOFF)
			state = TMAC_IDLE;
		return SUCCESS;
	}

	default event void RoutingHelpers.newNeighbour(uint16_t id){}

	command result_t MACComm.txRaw(uint8_t *msg, uint8_t length)
	{
		return call PhyComm.txPkt((PhyPktBuf*)msg,length);
	}
}
// end of implementation
