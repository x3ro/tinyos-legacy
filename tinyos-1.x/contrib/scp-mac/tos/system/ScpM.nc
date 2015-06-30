/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye, Asif Pathan
 *
 * This module implements SCP-MAC (scheduled channel polling)
 */


module ScpM
{
  provides {
    interface StdControl;
    interface MacMsg;
  }
  uses {
    interface StdControl as LplStdControl;
    interface MacMsg as LplMacMsg;
    interface LplControl;
    interface MacActivity as LplActivity;
    interface LplPollTimer;
    interface RadioState;
    interface Random;
    interface CarrierSense;
    interface CsThreshold;
    interface TxPreamble;
    interface PhyNotify;
    interface GetSetU32 as LocalTime;
    interface Timer as SyncTimer;
    interface Timer as NeighDiscTimer;
    interface TimerAsync as bootTimer;
    interface TimerAsync as TxTimer;
    interface TimerAsync as AdapTxTimer;
    interface TimerAsync as AdapPollTimer;
    interface Leds;
    interface UartDebug;
  }
}

implementation
{

#include "StdReturn.h"
#include "ScpConst.h"
#include "scpEvents.h"

// handle options that does not fully work on MicaZ
#ifdef PLATFORM_MICAZ

#ifndef SCP_DISABLE_ADAPTIVE_POLLING
#warning "MicaZ platform: adaptive channel polling does not work, \
so it is disabled."
#define SCP_DISABLE_ADAPTIVE_POLLING
#endif

#ifndef USE_FIXED_BOOT
#warning "MicaZ platform: automatic boot does not fully work. \
It is suggested to use manual boot by defining the macro USE_FIXED_BOOT."
#endif

#endif // PLATFORM_MICAZ

#if defined(SCP_MASTER_SCHEDULE) && !defined(USE_FIXED_BOOT)
#warning "SCP_MASTER_SCHEDULE option is being ignored, \
because USE_FIXED_BOOT is not defined."
#undef SCP_MASTER_SCHEDULE
#endif

// SCP constants
#define MAX_BASE_PKT_LEN (PHY_BASE_PRE_BYTES + PHY_MAX_PKT_LEN)
// radio wakeup delay in terms bytes can be transmitted
#define WAKEUP_DELAY_BYTES (PHY_WAKEUP_DELAY * 1024 / PHY_TX_BYTE_TIME + 1)
// minimum wakeup tone length (in bytes)
#define MIN_TONE_LEN (PHY_MAX_CS_EXT +  \
            + WAKEUP_DELAY_BYTES + LPL_MAX_POLL_BYTES + SCP_GUARD_TIME)
// tx wake up time before receiver's polling (in schedule)
#define TX_TIME_SCHED ((SCP_TONE_CONT_WIN + 1 \
            + PHY_MAX_CS_EXT) * PHY_CS_SAMPLE_INTERVAL / 1000 + 1 \
            + PHY_LOADTONE_DELAY)

#ifdef SCP_OLD_ADAPTIVE_LISTEN
// delay time for adaptive polling
#define ADAPTIVE_POLL_DELAY (SCP_TONE_CONT_WIN + 1 + PHY_WAKEUP_DELAY)
#endif

#define MAX_TONE_TIME (((uint32_t) PHY_TX_BYTE_TIME \
      * PHY_NUMBER_OF_TONES * MAX_BASE_PKT_LEN) / 1000 \
           + 1) + PHY_LOADTONE_DELAY
// find out maximum time to do carrier sense and wakeup
#define MAX_CS_WAKEUP_TIME (PHY_WAKEUP_DELAY + (SCP_TONE_CONT_WIN \
            + 1 + SCP_PKT_CONT_WIN + DIFS + PHY_MAX_CS_EXT) \
            * (uint32_t)PHY_CS_SAMPLE_INTERVAL / 1000 + 1 \
            + MIN_TONE_LEN * (uint32_t)PHY_TX_BYTE_TIME / 1000 + 1)
// maximum time for sending a broadcast pkt
#define MAX_BCAST_TIME (MAX_CS_WAKEUP_TIME + MAX_TONE_TIME + MAX_BASE_PKT_LEN \
            * (uint32_t)PHY_TX_BYTE_TIME / 1000 + 1)

// maximum time for sending a unicast pkt
#define MAX_UCAST_TIME (MAX_BCAST_TIME + CSMA_RTS_DURATION + CSMA_CTS_DURATION \
            + CSMA_ACK_DURATION + CSMA_PROCESSING_DELAY * 4)

// maximum numder of consecutive carrier sense failures
#define MAX_CS_FAILURES (SCP_TONE_CONT_WIN << 2)

// high-rate, adaptive polling period
#define HI_RATE_POLL_PERIOD MAX_UCAST_TIME

  // SCP states
  enum {
    IDLE,
    TX_TONE,
    TX_PKT
  };

  // packet format
  enum {
    BCAST_DATA_PKT,
    UCAST_DATA_PKT,
    SYNC_PKT
#ifndef USE_FIXED_BOOT
    ,SYNC_REQ_PKT
#endif
  };

  // schedule states
  enum {
    NOT_FOUND,
    FOUND,
    UPDATE
  };

#ifndef USE_FIXED_BOOT
  enum BootState {
    PASSIVE_DISCOVERY,
    ACTIVE_DISCOVERY,
    BOOT_DONE
  } bootState;  // initial synchronization state

  
#endif

  // state variables
  uint8_t state;  // LPL state
  uint8_t schedState; // state of my channel polling schedule

  // Variables for Tx
  bool txBuffered;  // if I have buffered a msg to send
  bool txStarted;  // if I have started Tx (i.e., pass it to CSMA)
  bool txSync;  // if I need to send sync
  bool txNotifyOldNeigh;  // if I need to send sync
  bool virtualCsIdle; // if virtual carrier sense indicates idle
  bool adapListenEnabled;  // if adaptive listen is enabled
  uint8_t txPktLen;
  uint16_t sendAddr;
  uint8_t toneLen;  // wakeup tone length (bytes)
  void* dataPkt;  // pointer to data packet to be sent
  SyncPkt syncPkt;  // sync packet buffer
  int16_t syncTimeDiff;
  uint8_t numCsFailures; // number of consecutive failures on carrier sense
  uint8_t passiveDiscPeriod; // Passive Discovery timeout in terms of Lpl Poll period
  uint8_t togglePin;

#ifndef SCP_DISABLE_ADAPTIVE_POLLING
  uint8_t adapPollAllowed;
  uint8_t pollType;  // the type of polling defined as below
  enum {
    REGULAR_POLL,
    ADAPTIVE_POLL_NO_PKT,  // adaptive polling but no pkt received
    ADAPTIVE_POLL_PKT      // adaptive polling with pkt received
  };
  uint8_t adapTxAllowed;
  uint8_t txType;  // the type of tx defined as below
  enum {
    REGULAR_TX,
    ADAPTIVE_TX_NO_PKT,
    ADAPTIVE_TX_PKT
  };
#endif

#ifdef SCP_SNOOPER_DEBUG
  uint8_t numRxSync;
#endif

#ifdef GLOBAL_SCHEDULE
  typedef struct {
    uint16_t syncNode;              // the node who initialized this schedule
    uint32_t schedAge;                      // schedule age
    uint32_t lastUpdt;                      // last local time when updating the schedule age    
  }mySchedule;
  typedef struct {
    uint16_t syncNode;              // the node who initialized this schedule
    uint32_t schedAge;                      // schedule age
    uint32_t lastUpdt;                      // update time
    uint16_t pollTime;              // neighbors polling time
  }nbSchedule;
  mySchedule      mySched;
  nbSchedule      nbSched;
  bool txNormSync; // if I need to send normal sync
  bool txNotifyOldNeigh;  // if I need to send sync
  uint8_t numSync;
  //uint32_t backoffTime;
  uint32_t numFired;
#endif


  // function prototypes
  void sendSYNC();
  void handleSYNC(void* pkt);
  void* handleBcastData(void* pkt);
  void handleUcastData(void *pkt, uint16_t pollTime);
  void syncSchedule(void* pkt, uint16_t pollTime);
  void syncSchedule_bcast(void* pkt, uint16_t polltime);
  task void sendPkt();
  uint16_t nextTxTime(uint16_t nextPollTime);
  void tryToTxTone();
  task void reportStarvation();
  result_t startMyOwnSchedule();
#ifndef USE_FIXED_BOOT
  void checkIfBootIsDone();
#endif
#ifdef GLOBAL_SCHEDULE
  uint32_t  GetCurrTime();
  void      setLplNormMode();
  void      ChangeMySchedule();
#endif

  command result_t StdControl.init()
  {
    // initialize LPL and lower level components

    state = IDLE;
    schedState = NOT_FOUND;
    txBuffered = FALSE;
    txStarted = FALSE;
    txSync = FALSE;
    virtualCsIdle = TRUE;
    numCsFailures = 0;
    syncPkt.csmaHdr.type = SYNC_PKT;
    passiveDiscPeriod = (uint8_t)((SCP_PASSIVE_DISCOVERY_TIMEOUT*SCP_POLL_PERIOD) / LPL_POLL_PERIOD);

#ifdef GLOBAL_SCHEDULE
    syncPkt.txLplMod = 0;
    syncPkt.chgSched = 0;
    numSync = 0;
    txNormSync = FALSE; 
    txNotifyOldNeigh = FALSE;

#endif
    

    call LplStdControl.init();  // initialize physical layer
#ifndef USE_FIXED_BOOT
       
    call LplControl.disableSleeping();
    call LplControl.disablePolling();
#endif
    call Leds.init();  // initialize LEDs

    // Mica2 radio seems sensitive to power supply. With 3V DC power adapter
    // and the old programming board, the radio sometimes can't be correctly
    // initialized (most of time, it can receive but can't transmit).
    // initialize UART debugging
    call UartDebug.init();

    return SUCCESS;
  }


  command result_t StdControl.start()
  {
    // start MAC and lower-level components
    //result_t result;
    call LplStdControl.start();  // start normal LPL first
    togglePin = 1;
#ifndef USE_FIXED_BOOT
// New boot protocol
  // skip passive discovery mode if timeout is zero
  #if SCP_PASSIVE_DISCOVERY_TIMEOUT !=0
      //#warning ("SCP is configured to do Passive discovery");
      bootState = PASSIVE_DISCOVERY;
      // we may need to send SYNC REQ with long preambles in active 
      // discovery mode. Set it here to avoid setting it
      // every time the boot timer fires in active mode.
      call LplControl.addPreamble((uint16_t) ((uint32_t)SCP_POLL_PERIOD * 1000 / PHY_TX_BYTE_TIME) + 1);
      // start a timer for Passive discovery mode timeout
      // no timer if we want to be in passive discovery mode forever
      
   #if SCP_PASSIVE_DISCOVERY_TIMEOUT != -1
      
      call bootTimer.start(TIMER_ONE_SHOT, SCP_PASSIVE_DISCOVERY_TIMEOUT*SCP_POLL_PERIOD);
   #endif
      
  
  // directly go to regular mode
  #else
      //#warning ("SCP is configured to not do Any discovery");
      bootState = BOOT_DONE;
      // proceed with own schedule
      startMyOwnSchedule();
  #endif
#elif defined(SCP_MASTER_SCHEDULE)
// Old boot protocol.
// Slaves just wait. Master sends out the beacon.
    // start a tx timer to broadcast my first schedule
    
    call TxTimer.start(TIMER_ONE_SHOT, 10);
#endif
    
    return SUCCESS;
  }


  command result_t StdControl.stop()
  {
    // stop clock and PHY, but MAC states are cleared when start again
    call LplStdControl.stop();  // stop physical layer
    call TxTimer.stop(); // stop timer
    state = IDLE;
    call UartDebug.txState(state);
    return SUCCESS;
  }


  command result_t MacMsg.send(void* msg, uint8_t length, uint16_t toAddr)
  {
    // standard command to send a message

    uint8_t result;

   
    // sanity check
    if (msg == 0 || length == 0 || length > PHY_MAX_PKT_LEN) {
      call UartDebug.txEvent(TX_REQUEST_REJECTED_MSG_ERROR);
      return FAIL;
    }
    // Don't accept Tx request if I have already accepted a request
    atomic {
      if (txBuffered == FALSE) {
        txBuffered = TRUE;
        result = 1;
      } else {
        result = 0;
      }
    }
    if (result == 0) {
      call UartDebug.txEvent(TX_REQUEST_REJECTED_NO_BUFFER);
      return FAIL;
    }
    call UartDebug.txEvent(TX_REQUEST_ACCEPTED);

    dataPkt = msg;
    txPktLen = length;
    sendAddr = toAddr;
    if (sendAddr == TOS_BCAST_ADDR) {
      ((CsmaHeader*)dataPkt)->type = BCAST_DATA_PKT;
    } else {
      ((CsmaHeader*)dataPkt)->type = UCAST_DATA_PKT;
    }
    txStarted = FALSE;

    return SUCCESS;
  }


  command result_t MacMsg.sendCancel(void* msg)
  {
    // cancel a message to be sent (i.e., previously called MacMsg.send)

    result_t result;
    if (msg != dataPkt) return FAIL;
    atomic {
      if (txBuffered && !txStarted) {
        txBuffered = FALSE;
        result = SUCCESS;
      } else {
        result = FAIL;
      }
    }
    if (result == SUCCESS) {
      return result;
    } else {
      return call LplMacMsg.sendCancel(msg);
    }
  }

async event result_t bootTimer.fired()
  {

    
#ifndef USE_FIXED_BOOT
        
      if (bootState  == BOOT_DONE) {
      
        // This can be safely ignored. This may happens when this timer fires immediately
        // after a SYNC pkt is received.
        return SUCCESS;
      
      }
      checkIfBootIsDone();
      return startMyOwnSchedule();


#else
      return SUCCESS;
#endif
 }

#ifndef USE_FIXED_BOOT
 
  // This function enables LPL polling if the boot process is not yet done.
  void checkIfBootIsDone()
  {
    // check the boot mode
    if(bootState != BOOT_DONE) {

      bootState = BOOT_DONE;
      call bootTimer.stop();

      //enable polling and periodic radio sleep
      call LplControl.enableSleeping();
      call LplControl.enablePolling();
    }
   }
#endif

  void sendSYNC()
  {
    // send sync packet now

#ifdef SCP_SNOOPER_DEBUG
    syncPkt.numRxSync = numRxSync;
    syncPkt.timeDiff = syncTimeDiff;
#endif
#ifdef GLOBAL_SCHEDULE
    syncPkt.syncNode = mySched.syncNode;
    syncPkt.schedAge = mySched.schedAge + ( call LocalTime.get()- mySched.lastUpdt );
    //Adjust age because the use of LPL long preamble
    if (syncPkt.txLplMod) syncPkt.schedAge = syncPkt.schedAge + SCP_POLL_PERIOD ; //+ 8;
#endif
    call LplMacMsg.send(&syncPkt, sizeof(SyncPkt), TOS_BCAST_ADDR);
    txStarted = TRUE;  // lower layer has a packet now
    state = TX_PKT;
    call UartDebug.txState(state);
  }


  void setLplSyncMode()
  {
    // set LPL into synchronized mode

    uint32_t backoffTime;
    call LplControl.addPreamble(0);  // no wakeup preamble
    call LplControl.setContWin(SCP_PKT_CONT_WIN);  // set contention window
#ifdef USE_FIXED_BOOT
    backoffTime = ((uint32_t)SCP_PKT_CONT_WIN + 1 + SCP_GUARD_TIME +
                + SCP_GUARD_TIME) * PHY_TX_BYTE_TIME / 1000 + 1 + 20
                + CSMA_BACKOFF_TIME;
#else
    //Note: The backofftime is set to SCP poll period to make sure that the SYNC request sent by a node when it is booting up
    // is not missed. The sync request message has a long preamble hence the node which is doing scp must wait for atleast one
    // scp period to get the start symbol.
    backoffTime = (uint32_t)PHY_BASE_PRE_BYTES * PHY_TX_BYTE_TIME / 1000 + 1
                 + SCP_POLL_PERIOD + 3;
#endif
    // backoff can be repeated to be compatible with normal LPL
    call LplControl.setBackoffTime(backoffTime, TRUE); 
    call LplControl.disableAutoReTx();
  }


  event void LplMacMsg.sendDone(void* msg, result_t result)
  {
    // message transmission is done

    uint8_t pktType;

    call UartDebug.txEvent(TX_MSG_DONE);
    state = IDLE;
    call UartDebug.txState(state);
    txStarted = FALSE;
    call Leds.redToggle();
#ifndef SCP_DISABLE_ADAPTIVE_POLLING
    if (schedState == UPDATE && result == SUCCESS) {  // normal SCP mode
      if (txType == REGULAR_TX) {  // just sent in regular polling time
        txType = ADAPTIVE_TX_NO_PKT;
      } else if (txType == ADAPTIVE_TX_NO_PKT) {  // sent in adaptive polling
        txType = ADAPTIVE_TX_PKT;
      }
      adapTxAllowed = SCP_NUM_HI_RATE_POLL;  // renew tx timer for adaptive tx
    }
#endif
    // process packet
    pktType = ((CsmaHeader *)msg)->type & 0x0f;
    // check if need to reset next sync packet time
    if (pktType == SYNC_PKT) {
      if (result == SUCCESS) {
        txSync = FALSE;
        if (schedState == FOUND) {  // just found a schedule
          schedState = UPDATE;
          setLplSyncMode();  // fully enter SCP mode 
        }
        call SyncTimer.setRemainingTime(SCP_SYNC_PERIOD);

#ifdef GLOBAL_SCHEDULE
          
	//turn off normal lpl mode after sending lpl sync packet
        if ( ((SyncPkt *)msg)->txLplMod ) {
          txNormSync = FALSE;
          setLplSyncMode();  // set back to SCP mode
	  syncPkt.txLplMod = 0;
#ifdef SCP_SNOOPER_DEBUG
	  syncPkt.normlpl++;
#endif
        }else if (((SyncPkt *)msg)->chgSched ) {
	  ChangeMySchedule();				
	  //will start to tx with new schedule
	  syncPkt.chgSched = 0;
          txNotifyOldNeigh = FALSE;   //finish to notify old neighbors.
#ifdef SCP_SNOOPER_DEBUG
	  syncPkt.chgnums++;
#endif
	}
#endif


      }
    }


    else if (pktType == BCAST_DATA_PKT) {
      if (result == SUCCESS && schedState == UPDATE) { // piggybacked sync
         txSync = FALSE;
         call SyncTimer.setRemainingTime(SCP_SYNC_PERIOD);
      }
      // restore piggybacked field
      ((CsmaHeader *)msg)->toAddr = TOS_BCAST_ADDR;
      txBuffered = FALSE;
      signal MacMsg.sendDone(msg, result);
    } else if (pktType == UCAST_DATA_PKT) {
      txBuffered = FALSE;
      signal MacMsg.sendDone(msg, result);
    }
  }


  event void* LplMacMsg.receiveDone(void* msg)
  {
    // received a message

    uint8_t pktType;
    call Leds.greenToggle();
    call UartDebug.txEvent(RX_MSG_DONE);

#ifndef SCP_DISABLE_ADAPTIVE_POLLING
    if (pollType == ADAPTIVE_POLL_NO_PKT) {
      pollType = ADAPTIVE_POLL_PKT; // if pkt Rx in adaptive polling, remember it
    }
    // keep doing high-rate polling
    // need to check remaining time before extend
    adapPollAllowed = SCP_NUM_HI_RATE_POLL;
#endif

    // check if it's sync packet
    pktType = ((CsmaHeader *)msg)->type & 0x0f;
    if (pktType == SYNC_PKT) {
#ifndef USE_FIXED_BOOT
      checkIfBootIsDone();
     
#endif
      handleSYNC(msg);
      return msg;
    }
#ifndef USE_FIXED_BOOT
    else if (pktType == SYNC_REQ_PKT) {
     
      return msg;
    }
#endif
    else if (pktType == BCAST_DATA_PKT) {
//#ifndef USE_FIXED_BOOT
      
//      checkIfBootIsDone();
//#endif
      return handleBcastData(msg);
    } else {  // unicast pkt
#ifdef SCP_HEAVY_SYNC
      // syncSchedule(msg, ((CsmaHeader*)msg)->sync_time); // ORIGINAL code
      handleUcastData(msg, ((CsmaHeader*)msg)->sync_time);
#endif
      return signal MacMsg.receiveDone(msg);
    }
  }


void syncSchedule(void* pkt, uint16_t pollTime)
  {
    uint16_t rxDelay, neighbVal;
    uint32_t        currTime;
    uint16_t        myPollTime;
    uint16_t localtimeVal1, localtimeVal2, lplpolltimerVal;
    uint16_t        avgPollTime;
    
    // Sanity check on polltime
    
    if (pollTime > SCP_POLL_PERIOD) {
      return;
    }    
    localtimeVal1 = call LocalTime.get();
    lplpolltimerVal = call LplPollTimer.get();
    currTime = call LocalTime.get();
    rxDelay = (uint16_t)( currTime - ((PhyPktBuf*)pkt)->info.timestamp ) + PHY_TIMESTAMP_DELAY;
    localtimeVal2 = call LocalTime.get();

    // Sanity check for timer wraparound
    if ((localtimeVal1 & 0xF0) != (localtimeVal2 & 0xF0)){
      return;             
    }
    


    
    
    // calculate neighbor's poll time relative to now
    if ( pollTime > rxDelay ) {
      neighbVal = pollTime - rxDelay;
    } else {
      neighbVal = (pollTime + SCP_POLL_PERIOD) - rxDelay;
    }
    myPollTime =(int16_t)call LplPollTimer.get();
    syncTimeDiff = myPollTime - neighbVal;

#ifdef GLOBAL_SCHEDULE
    //fill in my neighbors information
    nbSched.syncNode = ((SyncPkt *)pkt)->syncNode;
    nbSched.schedAge = ((SyncPkt *)pkt)->schedAge + rxDelay;
    nbSched.lastUpdt = currTime;
    nbSched.pollTime = neighbVal;
#endif
    if (schedState == NOT_FOUND) {  // this is the first schedule I received
      schedState = FOUND;
      // restart channel polling timer
      call LplPollTimer.stop();
      
      call LplPollTimer.start(SCP_POLL_PERIOD);
      call LplPollTimer.set(neighbVal);
      // start regular Tx timer
     
      call TxTimer.start(TIMER_REPEAT, SCP_POLL_PERIOD);
      call TxTimer.setRemainingTime(nextTxTime(neighbVal));
      // start sync timer for periodic schedule updates
     
      call SyncTimer.start(TIMER_REPEAT, SCP_SYNC_PERIOD);
      // start neigh discovery for periodic neighbor discovery updates
      
      call NeighDiscTimer.start(TIMER_REPEAT, NEIGH_DISC_PERIOD); 
#ifdef GLOBAL_SCHEDULE
      //use received schedule
      mySched.syncNode = nbSched.syncNode;
      mySched.schedAge = nbSched.schedAge;
      mySched.lastUpdt = call LocalTime.get();      
#endif
      // send SYNC now for unsynchronized neighbors
      txSync = TRUE; 
      syncPkt.txLplMod = 1;
      sendSYNC();
      
    } else{
      
#ifdef GLOBAL_SCHEDULE
      int32_t ageDiff;
      mySched.schedAge = mySched.schedAge + currTime - mySched.lastUpdt;
      mySched.lastUpdt = currTime;
      ageDiff = nbSched.schedAge - mySched.schedAge;
      
#ifdef SCP_SNOOPER_DEBUG
      syncPkt.OrglNode = mySched.syncNode;
      syncPkt.myPollTm = (int16_t)call LplPollTimer.get();
      syncPkt.nbPollTm = nbSched.pollTime;
      syncPkt.timeDiff = syncTimeDiff;
      syncPkt.CurrAge = mySched.schedAge;
      syncPkt.RecdAge = nbSched.schedAge;
      syncPkt.ageDiff = ageDiff;
#endif
      if ( syncTimeDiff >= -SCP_GUARD_TIME && syncTimeDiff <= SCP_GUARD_TIME
	   && mySched.syncNode == nbSched.syncNode
	   && ageDiff >= -SCP_GUARD_TIME && ageDiff <= SCP_GUARD_TIME)
	{
	  // SYNC of same schedule received
	  // set my polling time and age to avg values for robustness
	  avgPollTime = (myPollTime + neighbVal) >> 1;
          //if(togglePin == 1) {
          //  TOSH_SET_PW6_PIN();
          //  togglePin = 0 ;
          //} else {
          //  TOSH_CLR_PW6_PIN();
          //  togglePin = 1;
         // }
  
	  call LplPollTimer.set(avgPollTime);
	  call TxTimer.setRemainingTime(nextTxTime(avgPollTime));
	  mySched.schedAge = ( mySched.schedAge + nbSched.schedAge ) >> 1;
          call  NeighDiscTimer.setRemainingTime(NEIGH_DISC_PERIOD);	  
	}else if ( (ageDiff > AGE_GUARD_TIME )
		   || (ageDiff >= -AGE_GUARD_TIME && ageDiff <= AGE_GUARD_TIME
		       && nbSched.syncNode < mySched.syncNode )) {
	  
	  // Received older schedule or same schedule with lower syncnode id
	  mySched.schedAge = nbSched.schedAge;
	  mySched.syncNode = nbSched.syncNode;
	  mySched.lastUpdt = currTime;
	  call LplPollTimer.set( nbSched.pollTime );
	  txNotifyOldNeigh = TRUE;    //tell old neighor that schedule changed.
	  syncPkt.chgSched = 1;
#ifdef SCP_SNOOPER_DEBUG
	  if ( ageDiff > AGE_GUARD_TIME ) {
	    syncPkt.reason1++;
	  }
	  if ( ageDiff >= -AGE_GUARD_TIME && ageDiff <= AGE_GUARD_TIME
	       && nbSched.syncNode < mySched.syncNode ) {
	    
	    syncPkt.reason2++;
	  }
#endif
	} else if (ageDiff < -(2 * AGE_GUARD_TIME) ) {
 
          call  NeighDiscTimer.setRemainingTime(8192);
 
        }
      
#else
      if ((syncTimeDiff >= 1 && syncTimeDiff <= SCP_GUARD_TIME)
	  || (syncTimeDiff <= -1) && syncTimeDiff >= -SCP_GUARD_TIME){
	// set my schedule to the neighbor's
	call LplPollTimer.set(neighbVal);
	call TxTimer.setRemainingTime(nextTxTime(neighbVal));
      } else {
        // some thing is wrong
        if (syncTimeDiff > SCP_GUARD_TIME || syncTimeDiff < -SCP_GUARD_TIME) {
	  /*
	    call UartDebug.txByte((uint8_t)(pollTime & 0xff));
	    call UartDebug.txByte((uint8_t)((pollTime >> 8) & 0xff));
	    call UartDebug.txByte((uint8_t)(rxDelay & 0xff));
	    call UartDebug.txByte((uint8_t)((rxDelay >> 8) & 0xff));
	    call UartDebug.txByte((uint8_t)(neighbVal & 0xff));
	    call UartDebug.txByte((uint8_t)((neighbVal >> 8) & 0xff));
	    call UartDebug.txByte((uint8_t)(syncTimeDiff & 0xff));
	    call UartDebug.txByte((uint8_t)((syncTimeDiff >> 8) & 0xff));
	  */     
	}
      }
#endif
    }
  }
  
  uint16_t nextTxTime(uint16_t nextPollTime)
  {
    // return next Tx time given next channel polling time
    if (nextPollTime > TX_TIME_SCHED) {  // have enough time
      return (nextPollTime - TX_TIME_SCHED);
    } else {  // not enough time for current cycle
      return (nextPollTime + SCP_POLL_PERIOD - TX_TIME_SCHED);
    }
  }


  void handleSYNC(void* pkt)
  {
    // internal handler for SYNC packet

    SyncPkt* packet = (SyncPkt*)pkt;
#ifdef SCP_SNOOPER_DEBUG
    numRxSync++;
#endif
     syncSchedule(pkt, packet->pollTime);   // synchronize my schedule
  }


  void* handleBcastData(void* pkt)
  {
    // handle broadcast data

    void* tmp;
    CsmaHeader* packet = (CsmaHeader*)pkt;
    #ifdef GLOBAL_SCHEDULE
      if (schedState != NOT_FOUND) { 
         syncSchedule_bcast(pkt, packet->toAddr);
      }
    #else
      if (schedState != NOT_FOUND) {
         syncSchedule(pkt, packet->toAddr);
      }
    #endif
    // restore piggybacked bytes
    packet->toAddr = TOS_BCAST_ADDR;
    // signal upper layer
    tmp = signal MacMsg.receiveDone(packet);
    return tmp;
  }


  void startCarrSense()
  {
    // start carrier sense

    uint16_t backoffSlots;
    backoffSlots = (call Random.rand() % SCP_TONE_CONT_WIN) + 1;
    toneLen = SCP_TONE_CONT_WIN + 1 - (uint8_t)backoffSlots + MIN_TONE_LEN;
    call CarrierSense.start(backoffSlots);
    call UartDebug.txEvent(CARRIER_SENSE_STARTED);
  }

  //  this function starts a new schedule and initializes all internal timers, if the schedule
  //  for the node is not yet determined.
  //  Returns success if a new schedule is started
  result_t startMyOwnSchedule()
  {
    if (schedState == NOT_FOUND) { // first schedule broadcast
      schedState = FOUND;
      // restart channel polling timer
      call LplPollTimer.stop();
     
      call LplPollTimer.start(SCP_POLL_PERIOD);
      // start regular Tx timer
     
      call TxTimer.start(TIMER_REPEAT, SCP_POLL_PERIOD);
      call TxTimer.setRemainingTime(nextTxTime(SCP_POLL_PERIOD));
      // start sync timer for periodic schedule updates
      
      call SyncTimer.start(TIMER_REPEAT, SCP_SYNC_PERIOD);
      // start neigh discovery for periodic neighbor discovery updates
     
      call NeighDiscTimer.start(TIMER_REPEAT, NEIGH_DISC_PERIOD);
      // send SYNC now for unsynchronized neighbors
#ifdef GLOBAL_SCHEDULE
      mySched.syncNode = TOS_LOCAL_ADDRESS;
      mySched.schedAge = 0;
      mySched.lastUpdt = call LocalTime.get();      
#endif
      syncPkt.txLplMod = 1;
      sendSYNC();
      return SUCCESS;
    }
    return FAIL;
  }

  async event result_t TxTimer.fired()
  {
    // scheduled sending should only happen when radio in sleep mode
    // if radio is not in sleep state, it must have other activities
   
    call UartDebug.txEvent(TX_TIMER_FIRED);

#ifdef SCP_MASTER_SCHEDULE
    if ( SUCCESS == startMyOwnSchedule()) {
      return SUCCESS;
    }
#endif
#ifndef SCP_DISABLE_ADAPTIVE_POLLING
   
    call AdapTxTimer.start(TIMER_REPEAT, HI_RATE_POLL_PERIOD);
    if (txType == REGULAR_TX) {
      // previously tried Tx in regular polling, but didn't succeed
      adapTxAllowed = 0;  // no adaptive Tx unless the current Tx succeeds
      // try to send wakeup tone
      tryToTxTone();
    } else if (txType == ADAPTIVE_TX_NO_PKT) {
      // previously sent in regular polling, but didn't send adaptively
      adapTxAllowed = 0;
      txType = REGULAR_TX;
      // try to send wakeup tone
      tryToTxTone();
    } else if (txType == ADAPTIVE_TX_PKT) {
      // previously sent pkt in adaptive polling
      // will use adaptive polling instead of regular polling
      adapTxAllowed = SCP_NUM_HI_RATE_POLL;
      txType = ADAPTIVE_TX_NO_PKT;
    }
#else  // adaptive polling is disabled
    // try to send wakeup tone
    tryToTxTone();
#endif
    return SUCCESS;
  }


  async event result_t AdapTxTimer.fired()
  {
   
    // adaptive Tx timer fired
#ifndef SCP_DISABLE_ADAPTIVE_POLLING
    if (adapTxAllowed == 0) {  // can't send any more
      call AdapTxTimer.stop();
    } else {
      // check if have enough time for adaptive Tx
      if (call TxTimer.getRemainingTime() < HI_RATE_POLL_PERIOD) {
        call AdapTxTimer.stop();
        adapTxAllowed = 0;
      } else {  // have enough time, keep adaptive Tx timer
        adapTxAllowed--;
        if (txType == REGULAR_TX) {  // may be redundant, but just to be safe
          txType = ADAPTIVE_TX_NO_PKT;
        }
        // try to send wakeup tone
        tryToTxTone();
      }
    }
#endif
    return SUCCESS;
  }


  void tryToTxTone()
  {
    // try to turn on radio to transmit wakeup tone

    int8_t result;
    if (!txBuffered && !txSync
#ifdef GLOBAL_SCHEDULE
        && !txNotifyOldNeigh && !txNormSync
#endif  
    ) {  // no packet to send
      call UartDebug.txEvent(NO_PKT_TO_SEND);
      return;
    }
    if (!virtualCsIdle) {  // virtual carrier sense busy
      call UartDebug.txEvent(VIRTUAL_CS_BUSY);
      return;
    }
    if (call RadioState.get() == RADIO_SLEEP) {
      // wake up radio and start carrier sense
      result = call RadioState.idle();
      if (result == SUCCESS_DONE) {
        call UartDebug.txEvent(RADIO_IDLE_DONE);
        state = TX_TONE;
        call UartDebug.txState(state);
        call TxPreamble.preload(0);
        startCarrSense();
      } else if (result == SUCCESS_WAIT) {
        // will do it after wakeupDone
        call UartDebug.txEvent(RADIO_IDLE_WAIT);
        state = TX_TONE;
        call UartDebug.txState(state);
      } else {
        // failed to turn radio into idle state
        call UartDebug.txEvent(RADIO_IDLE_FAILED);
      }
    }
  }


event result_t SyncTimer.fired()
{

	txSync = TRUE;
       
        call UartDebug.txEvent(SYNC_TIMER_FIRED);
        return SUCCESS;

}


event result_t NeighDiscTimer.fired()
{
        
	syncPkt.txLplMod =  1;
        setLplNormMode();
        txSync = TRUE;
        txNormSync = TRUE;
       
        call UartDebug.txEvent(NEIGH_DISC_TIMER_FIRED);
        return SUCCESS;
}


async event result_t LplPollTimer.fired()
  {
    // regular channel polling timer fired
#ifndef SCP_DISABLE_ADAPTIVE_POLLING
    // start high-rate polling timer in case a pkt will be received
   
    call AdapPollTimer.start(TIMER_REPEAT, HI_RATE_POLL_PERIOD);
    if (pollType == ADAPTIVE_POLL_PKT) { // previous received adaptive pkts
      // re-check with adaptive polling
      adapPollAllowed = SCP_NUM_HI_RATE_POLL;
    } else {
      // no adaptive polling unless receive pkt in this regular polling
      adapPollAllowed = 0;
    }
    pollType = REGULAR_POLL;
#endif
    return SUCCESS;
  }


  async event result_t AdapPollTimer.fired()
  {
   
    // adaptive polling timer fired
#ifndef SCP_DISABLE_ADAPTIVE_POLLING
    call UartDebug.txEvent(ADAPTIVE_TIMER_FIRED);
    if (adapPollAllowed == 0) {
      // no more high-rate polling is needed
      call AdapPollTimer.stop();
    } else {
      // check if have enough time for adaptive polling
      if (call LplPollTimer.get() < HI_RATE_POLL_PERIOD) {
        call AdapPollTimer.stop();
        adapPollAllowed = 0;
      } else {  // have enough time, keep adaptive polling timer
        if (pollType == REGULAR_POLL) {  // just did regular polling
          pollType = ADAPTIVE_POLL_NO_PKT;  // no adaptive pkt received yet
        }
        adapPollAllowed--;
        call LplControl.pollChannel();  // poll channel activity
      }
    }
#endif
    return SUCCESS;
  }


  async event result_t RadioState.wakeupDone()
  {
    // radio wakeup is done -- it becomes stable now

    if (state == TX_TONE) {
      call UartDebug.txEvent(RADIO_IDLE_DONE);
      call TxPreamble.preload(0);
      startCarrSense();
    }
    return SUCCESS;
  }


  async event result_t CarrierSense.channelIdle()
  {
    // physical carrier sense indicate channel idle

    if (state != TX_TONE) return FAIL;
    call UartDebug.txEvent(CHANNEL_IDLE_DETECTED);
#ifdef SCP_OLD_ADAPTIVE_LISTEN
    // adaptive listen enabled
    call AdaptiveTimer.stop(); // stop possible adaptive polling timer
#endif
    // disable channel polling when sending tone
    call LplControl.disablePolling();
    // send wakeup tone now
    call TxPreamble.start(toneLen); // toneLen is determine before carr sense
    numCsFailures = 0;  // clear CS failure count
    return SUCCESS;
  }


  async event result_t CarrierSense.channelBusy()
  {
    // physical carrier sense indicate channel busy

    if (state != TX_TONE) return FAIL;
    // can't send wakeup tone now
    call UartDebug.txEvent(CHANNEL_BUSY_DETECTED);
    // put radio back to sleep, so that will perform normal polling
    //    call RadioState.sleep(); // Commented out to avoid interfering with Lpl
    state = IDLE;
    call UartDebug.txState(state);
    numCsFailures++;  // increment CS failure count
    if (numCsFailures > MAX_CS_FAILURES) {
      post reportStarvation();  // ask radio be more aggressive
    }
    return SUCCESS;
  }


  task void reportStarvation()
  {
    // report starvation on Tx, so that radio will become more aggressive
    call CsThreshold.starved();
    numCsFailures = 0;  // clear CS failure count to try new threshold
  }


  async event result_t PhyNotify.startSymSent(void* packet)
  {
    // just sent out start symbol of a packet

    // need to put timestamp on sync packet or broadcast data
    call UartDebug.txEvent(START_SYMBOL_SENT);
    if ((void*)(&syncPkt) == packet) {
      syncPkt.pollTime = call LplPollTimer.get();

    } else if (dataPkt == packet && sendAddr == TOS_BCAST_ADDR) {
      ((CsmaHeader*)packet)->toAddr = call LplPollTimer.get();
    }
    return SUCCESS;
  }


  async event result_t PhyNotify.startSymDetected(void* packet, uint8_t bitOffset)
  {
    // just received a start symbol

    call UartDebug.txEvent(START_SYMBOL_DETECTED);
    return SUCCESS;
  }


 task void sendPkt()
  //  void sendPkt()
  {
    // check packet Tx flags
    if (txStarted) {  // lower layer already has a packet to send
      call LplActivity.reSend();
    } else {  // start a new Tx
      if ( 0 
#ifdef GLOBAL_SCHEDULE
    || txNormSync || txNotifyOldNeigh
#endif 
      ) {
        sendSYNC();
      } else {
        if (txBuffered) {
          if (sendAddr == TOS_BCAST_ADDR) {  // will piggyback sync
            // send data packet now
            call LplMacMsg.send(dataPkt, txPktLen, sendAddr);
            txStarted = TRUE;
          } else {  // unicast
            if (txSync
#ifdef GLOBAL_SCHEDULE
   || txNotifyOldNeigh || txNormSync
#endif
            ) {
	     
              sendSYNC(); // sync has higher priority than unicast data
            } else {  // only has unicast data
              call LplMacMsg.send(dataPkt, txPktLen, sendAddr);
              txStarted = TRUE;
            }
          }
        } else {  // only has sync to send
          if (txSync
#ifdef GLOBAL_SCHEDULE
   || txNotifyOldNeigh || txNormSync
#endif
          ) sendSYNC();
        }
      }
    }
  }

  async event void TxPreamble.done()
  {
    // sending start symbol is done, time to send a packet

    // re-enable channel polling when sending tone
    call LplControl.enablePolling();
    call UartDebug.txEvent(TX_TONE_DONE);
    state = TX_PKT;
    call UartDebug.txState(state);
    post sendPkt();
//    sendPkt();
  }


  event void LplActivity.virtualCSBusy()
  {
    // virtual carrier sense is busy now

    virtualCsIdle = FALSE;
    call UartDebug.txEvent(VIRTUAL_CS_BUSY);
  }


  event void LplActivity.virtualCSIdle()
  {
    // virtual carrier sense is idle now

    virtualCsIdle = TRUE;
    if (schedState != UPDATE) return;  // not in full SCP mode
    call UartDebug.txEvent(VIRTUAL_CS_IDLE);

#ifdef SCP_OLD_ADAPTIVE_LISTEN
    // adaptive listen enabled
    // check if have enough time before regular polling
    if (call LplPollTimer.get() < MAX_UCAST_TIME) return;
  
    call AdaptiveTimer.start(TIMER_ONE_SHOT, ADAPTIVE_POLL_DELAY);
    call UartDebug.txEvent(ADAPTIVE_TIMER_STARTED);
    if (txBuffered) {  // have pkt to send
      // check if I still have enough time before regular polling

      radioOnTxTone();  // turn on radio to send wakeup tone
    }
#endif
  }


  event void LplActivity.radioDone(result_t result)
  {
    // CSMA is done with radio for packet Tx or Rx
    // if result is SUCCESS, can start adaptive sending
    if (schedState != UPDATE) return;  // not in full SCP mode
    call UartDebug.txEvent(CSMA_RADIO_DONE);

#ifdef SCP_OLD_ADAPTIVE_LISTEN
    // adaptive listen enabled
    if (result == FAIL) return;  // no adaptive listen if just failed
    // check if have enough time before regular polling
    if (call LplPollTimer.get() < MAX_UCAST_TIME) return;
    call UartDebut.txByte((uint8_t)208);
    call AdaptiveTimer.start(TIMER_ONE_SHOT, ADAPTIVE_POLL_DELAY);
    call UartDebug.txEvent(ADAPTIVE_TIMER_STARTED);
    if (result == SUCCESS && txBuffered) {  // have pkt to send
      radioOnTxTone();  // turn on radio to send wakeup tone
    }
#endif
  }


#ifdef SCP_OLD_ADAPTIVE_LISTEN
  async event result_t AdaptiveTimer.fired()
  {
    // timer fired for adaptive channel polling

    call LplControl.pollChannel();
    return SUCCESS;
  }
#endif

  
#ifdef GLOBAL_SCHEDULE

 uint32_t GetCurrTime()
  {
    return call LocalTime.get();
  }
  
  //this function used when piggybacked broadcast message is received.
  void syncSchedule_bcast(void* pkt, uint16_t pollTime)
  {
    
    uint16_t rxDelay, neighbVal;
    uint32_t        currTime;
    uint16_t        myPollTime;
    uint16_t        avgPollTime;
    
    currTime = call LocalTime.get();
    rxDelay = (uint16_t)( currTime - ((PhyPktBuf*)pkt)->info.timestamp ) + PHY_TIMESTAMP_DELAY;
    // calculate neighbor's poll time relative to now
    if ( pollTime > rxDelay ) {
      neighbVal = pollTime - rxDelay;
    } else {
      neighbVal = (pollTime + SCP_POLL_PERIOD) - rxDelay;
    }
    myPollTime =(int16_t)call LplPollTimer.get();
    syncTimeDiff = myPollTime - neighbVal;
    if ((syncTimeDiff >= 1 && syncTimeDiff <= SCP_GUARD_TIME)
	|| (syncTimeDiff <= -1) && syncTimeDiff >= -SCP_GUARD_TIME){
      
      // set my schedule to the avg polling time
      avgPollTime = (myPollTime + neighbVal) >> 1;
      call LplPollTimer.set(avgPollTime);
      call TxTimer.setRemainingTime(nextTxTime(avgPollTime));
    }
  }
  

//this function used when unicast message is received and SCP_HEAVY_SYNC is defined.
  void handleUcastData(void* pkt, uint16_t pollTime)
  {
    
    uint16_t rxDelay, neighbVal;
    uint32_t        currTime;
    uint16_t        myPollTime;
    uint16_t        avgPollTime;
    uint16_t localtimeVal1, localtimeVal2, lplpolltimerVal;
    
    
    // Sanity check on polltime
    
    if (pollTime > SCP_POLL_PERIOD) {
      return;
    }    
    localtimeVal1 = call LocalTime.get();
    lplpolltimerVal = call LplPollTimer.get();
    currTime = call LocalTime.get();
    rxDelay = (uint16_t)( currTime - ((PhyPktBuf*)pkt)->info.timestamp ) + PHY_TIMESTAMP_DELAY;
    localtimeVal2 = call LocalTime.get();
    
    // Sanity check for timer wraparound
    if ((localtimeVal1 & 0xF0) != (localtimeVal2 & 0xF0)){
      return;             
    }
    
    // calculate neighbor's poll time relative to now
    if ( pollTime > rxDelay ) {
      neighbVal = pollTime - rxDelay;
    } else {
      neighbVal = (pollTime + SCP_POLL_PERIOD) - rxDelay;
    }
    myPollTime =(int16_t)call LplPollTimer.get();
    syncTimeDiff = myPollTime - neighbVal;
    if ((syncTimeDiff >= 1 && syncTimeDiff <= SCP_GUARD_TIME)
	|| (syncTimeDiff <= -1) && syncTimeDiff >= -SCP_GUARD_TIME){
      
      // set my schedule to the avg polling time
      avgPollTime = (myPollTime + neighbVal) >> 1;
      call LplPollTimer.set(avgPollTime);
      call TxTimer.setRemainingTime(nextTxTime(avgPollTime));
    }
  }
  


  


void setLplNormMode()
  {
    // set LPL into synchronized mode
    call LplControl.addPreamble((uint16_t) ((uint32_t)SCP_POLL_PERIOD * 1000 / PHY_TX_BYTE_TIME) + 1);
    call LplControl.setContWin(CSMA_CONT_WIN);  //set contention window to CSMA
    call LplControl.enableAutoReTx();

  }

void ChangeMySchedule()
  {
    //set the following after sending sync
    uint16_t pollTime;              // neighbors polling time
    pollTime = call LplPollTimer.get();
    call TxTimer.setRemainingTime(nextTxTime( pollTime ));
  }
#endif
} // end of implementation
