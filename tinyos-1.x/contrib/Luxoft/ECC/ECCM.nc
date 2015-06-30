/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*  
 * $Id: ECCM.nc,v 1.2 2003/12/26 11:36:35 korovkin Exp $
 */
/*
 * This module provides the error correction functionality by sending
 * and receiving acknowledgement packets. 
 * This module keeps an array of structures decscribing messages already
 * sent. There are two options:
 * 1. We have a broadcast message. In this case we go the traditional way.
 * 2. We have a message to be sent to particular mote. In this case we
 * put the pessage (neater it's pointer) to the array and wait for an ack 
 * message from the receiver. If ACK message comes we remove message from 
 * the array and do sendDone.
 *
 * We also have the timer counting timeouts. Each time timer ticks we pass
 * through the array and do "if (--timeout <= 0) message sending failed"
 * if there are no messages we stop the timer. We start it on message sending.
 *
 * We collect the channel quality data we give to upper level. We make 
 * timer ticking every predefined period each time we reset counter and make 
 * data available to upper level
 */

includes AM;
includes ECC;
#ifdef _WITH_CHANQ_
includes ChanQ;
#endif
/* Length of the messages waiting for ACK array */
//for now let's set it as SEND_QUEUE_SIZE
#ifndef ACK_ARRAY_SIZE
#define ACK_ARRAY_SIZE 32 
#endif

/* Length of the connection quality array 
 * It's size have to be the same as the length of the routing table
 * if we don't want to miss a host
 */
#ifndef CHST_ARRAY_SIZE
#define CHST_ARRAY_SIZE 16
#endif

/* Granularity of the timeout timer */
#ifndef TIMEOUT_DELTA
#define TIMEOUT_DELTA 100
#endif

/* Default timeout (in timeout granularity) */
//Let it be ~1 sec
#ifndef DEF_TIMEOUT
#define DEF_TIMEOUT 10
#endif

/* Period we do data collection */
#ifndef CQ_DELTA
#define CQ_DELTA 10000
#endif

// debug mode to be used for this module
#define DBG_ECC DBG_USR1

// name of the ACK enable attribute
#define ACKENABLE "ack_ena"

// name of commands to enable/disable ACK sending
#define ACKON "AckOn"
#define ACKOFF "AckOff"

module ECCM
{
  provides
  {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface NeighTabUpdater;
#ifdef _WITH_CHANQ_
    command result_t gimme(ChanQMsg* data);
#endif
  }
  uses 
  {
    interface Leds;
    interface Timer as TimeoutTimer;
#ifdef _WITH_CHANQ_
    interface Timer as CQTimer;
#endif
    interface BareSendMsg as HWSend;
    interface ReceiveMsg as HWReceive;
    interface StdControl as HWControl;
    interface AttrRegister as Enable;
    interface CommandRegister as AckOn;
    interface CommandRegister as AckOff;
  }
}
implementation
{
  typedef uint8_t token_t; //type of the uneque token 
  typedef uint8_t idx_t; //type of index in the array

  /*
   * Structure that descibes the array of messages sent and waiting for 
   * ACK to be received
   */
  typedef struct SentMsg 
  {
    TOS_MsgPtr pMsg; //message pointer
    uint16_t timeout; //timeout we wait for ACK packet
    token_t token; //The quazy-uneque message token sent and returned
  } SentMsg;
  
  enum //possible timeout values
  {
    NO_TIMEOUT = 0,
    TO_INFINITY = 0xFFFF
  };

  /* Enumeration of possible timer actions */ 
  typedef enum _TimerAction
  {
    STOP = 0,
    START = 1
  } TimerAction;

  enum //flags for channel statistics information
  {
    NODE_VALID = 1 //if this node is valid
  };
  
  /* Structure describes channel statistics */
  typedef struct _ChannelStat
  {
    uint16_t addr; //node address
    uint16_t nResend; //number of resent packets to upper level
    uint16_t nRsndCount; //resent packets counter
    uint8_t flags; //flags related to the node
  } ChannelStat;

  SentMsg sentMessages[ACK_ARRAY_SIZE]; //Array of messages waiting for ACK
  ChannelStat chStat[CHST_ARRAY_SIZE]; //Array of channel statistics
  token_t tokenCnt; //Token counter
  TOS_Msg ackMsg; //Message buffer used to send ACKs
  TOS_MsgPtr pAckMsg; //ACK message pointer
  bool busy; //If we are now sending a packet
  TimerAction tmStatus; //Timer status  
  bool enabled = FALSE; //If ACK handling algorithm is enabled
  TOS_MsgPtr pFailedMsg; //The message failed to send due to ack sending

  task void SendAckTask();

  /* 
   * Function initializes the message waiting for ACK description
   */
  static inline void InitCache(idx_t idx)
  {
    sentMessages[idx].token = 0; // Zero token means empty slot
    sentMessages[idx].pMsg = 0;  // Null message pointer means empty slot
    sentMessages[idx].timeout = NO_TIMEOUT; //No timeout for this slot
  }
  /*
   * Function initializes array of messages waiting for ACK
   */
  static inline void InitMsgArray()
  {
    idx_t i; // index variable
    for (i = 0; i < ACK_ARRAY_SIZE; i++)
      InitCache(i);
  }

  /*
   * Function searches for the available slot int the array of messages
   * waiting for ACK.
   * Parameters: 
   * pidx - pointer index to the available index
   * Return: SUCCESS if slot is available and FAIL otherwise
   */
  static inline result_t FindAvail(uint8_t* pidx)
  {
    idx_t i; //just an index
    
    for (i = 0; i < ACK_ARRAY_SIZE; i++)
    {
      if (sentMessages[i].token == 0 && sentMessages[i].pMsg == 0)
      {
        *pidx = i;
        return SUCCESS;
      }
    }
    return FAIL;
  }
   
  /*
   * Find index of the message in the array of messages waiting for ACK
   * Parameters: 
   * token - message token
   * pidx - pointer index to the available index
   * Return: SUCCESS if slot is available and FAIL otherwise
   */
  static inline result_t FindMsg(token_t token, idx_t* pidx)
  {
    idx_t i; //just an index
    for (i = 0; i < ACK_ARRAY_SIZE; i++)
    {
      if (sentMessages[i].token == token)
      {
        *pidx = i;
        return SUCCESS;
      }
    }
    return FAIL;
  }
  
  /*
   * Function makes token for the message
   */
  static inline token_t GetToken()
  {
    tokenCnt++;
    if (tokenCnt == 0) //If we got the overflow let's wrap the token
      tokenCnt = 1;
    return tokenCnt;
  }
  
  /*
   * Function starts/stops timer 
   * Parameters:
   * on - START(1) - starts timer, STOP(0) - stops it
   */
  static inline result_t goTimer(TimerAction on)
  {
    TimerAction localTmStatus; //local timer status (to avoid race condition)
    atomic
    {
      localTmStatus = tmStatus;
      if (on == START)
        tmStatus = START;
      if (on == STOP)
        tmStatus = STOP;
    }
    if (on == START)
    {  
      switch (localTmStatus)
      {
        case STOP:
        {
          dbg(DBG_ECC, "ECC: Timer started\n");
          return call TimeoutTimer.start(TIMER_REPEAT, TIMEOUT_DELTA);
        }
        case START:
          return SUCCESS;
        default:
          return FAIL;
      }
    }
    else
    {
      switch (localTmStatus)
      {
        case START:
        {
          dbg(DBG_ECC, "ECC: Timer stopped\n");
          return call TimeoutTimer.stop();
        }
        case STOP:
          return SUCCESS;
        default:
          return FAIL;
      }
    }
    return FAIL;
  }

  /*
   * Function initializes the cell at given index in the 
   * chanel statistics array
   */
  static inline void newStatCell(idx_t idx)
  {
    chStat[idx].nResend = 0;
    chStat[idx].nRsndCount = 0;
  }


  /*
   * Function invalidates the cell at given index in the 
   * chanel statistics array
   */
  static inline void invalStatCell(idx_t idx)
  {
    chStat[idx].flags &= ~NODE_VALID;
  }

  /*
   * Function initializes the array of channel statistic data
   */
  static inline void initStatArray()
  {
    idx_t i; //just index variable
    for (i = 0; i < CHST_ARRAY_SIZE; i++)
    {
      invalStatCell(i);
      newStatCell(i);
    }
  }

  /* 
   * Function checks if the cell is for the mote with address provided
   */
  static inline bool forMote(ChannelStat* chstat, uint16_t addr)
  {
    if (chstat->flags & NODE_VALID && chstat->addr == addr)
      return TRUE;
    else
      return FALSE;
  }

  /* 
   * Function returns the index in channel statistics table for 
   * the specified mote address into the index specified by pointer
   * returns SUCCESS if found and FAIL otherwise
   * otherwise
   */
  static inline result_t getIdx(uint16_t addr, idx_t* pidx)
  {
    idx_t i; //just index variable
    for (i = 0; i < CHST_ARRAY_SIZE; i++)
    {
      if (forMote(&chStat[i], addr))
      {
        *pidx = i;
        return SUCCESS;
      }
    }
    return FAIL;
  }

  /*
   * Function increments the resend counter for the mote with the 
   * address provided in the addr variable
   */
  static inline void incResend(uint16_t addr)
  {
    idx_t idx; //just index variable
    if (getIdx(addr, &idx) == SUCCESS)
        chStat[idx].nRsndCount++; //Let's don't care about overflow - zero it
  }
  
  /*
   * Exported interface functions
   */
  static inline result_t regCommands()
  {
    ParamList paramList;
    paramList.numParams = 0;
    return rcombine(call AckOn.registerCommand(ACKON, VOID, 0, &paramList),
      call AckOff.registerCommand(ACKOFF, VOID, 0, &paramList));
  }

  /*
   * StdControl interface functions
   */  
  command result_t StdControl.init() 
  {
    result_t ok1, ok2, ok3; //results of operations
    tokenCnt = 1;
    InitMsgArray();
    initStatArray();
    busy = FALSE;
    tmStatus = STOP;
    enabled = TRUE;
    pAckMsg = NULL;
    pFailedMsg = NULL;
    ok1 = call Enable.registerAttr(ACKENABLE, UINT16, 1);
    ok3 = regCommands();
    ok2 = call HWControl.init();
    return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start()
  {
    result_t ok = call HWControl.start();
#ifdef _WITH_CHANQ_
    call CQTimer.start(TIMER_REPEAT, CQ_DELTA);
#endif
    return ok;
  } 

  command result_t StdControl.stop()
  {
    goTimer(STOP);
    call HWControl.stop();
    return SUCCESS;
  } 
  
  /*
   * BareSendMsg interface functions
   */
  /* 
   * Note: this function is not absolutly BARE. It cares about 
   * message destination addr and message token fields.
   */
  command result_t Send.send(TOS_MsgPtr pMsg)
  {
    idx_t idx; //index of the available 
    result_t ok; //operational result
    bool localEnabled; //local value for global variable 
    bool localBusy; //local Busy flag
    
    atomic
    {
      localEnabled = enabled;
      localBusy = busy;
    }
    //If we are sending ACK message we should not send any other
    if (localBusy)
    {
      atomic
      {
        if (pFailedMsg == NULL)
        {
          pFailedMsg = pMsg;
          dbg(DBG_ECC, "ECC: UNABLE insert message: 0x%x\n", pMsg->addr);
          ok = SUCCESS;
        }
        else
        {
          dbg(DBG_ECC, "ECC: UNABLE INSERT pFailedMsg != NULL: 0x%x\n", 
            pMsg->addr);
          ok = FAIL;
        }
      }
      //But we can't send FAIL immediately QueueSend in this case will 
      //resend message. Let's wait for sendDone and do this there
      return ok;
    }
    pMsg->orig = TOS_LOCAL_ADDRESS;

    // It's wrong to want ACK to broadcast messages
    if (localEnabled && pMsg->addr != TOS_BCAST_ADDR)
    {
      bool noSpace = FALSE; //if no available slot
      
      // Let's put the message to array of ACK waiting messages
      //Fail if there is no available slot
      atomic
      {
        if (FindAvail(&idx) == SUCCESS)
        {
          sentMessages[idx].token = GetToken();
          pMsg->token = sentMessages[idx].token;
          sentMessages[idx].pMsg = pMsg;
          sentMessages[idx].timeout = TO_INFINITY;
          dbg(DBG_ECC, "ECC: inserted %d, 0x%x\n", idx, pMsg->addr);
        }
        else
          noSpace = TRUE;
      }
      if (noSpace)
      {
        dbg(DBG_ECC, "ECC No slot available\n");
        return FAIL;
      }
      /* Once we put message to array we need to check it */
      goTimer(START);
      atomic
      {
        busy = TRUE;
      }
    }
    // All said, let's call the send from lower level
    ok = call HWSend.send(pMsg);
    dbg(DBG_ECC, "ECC: sent to lower %s\n", 
      (ok == SUCCESS) ? "SUCCESS": "FAIL");
    //If we failed, let's clear chache
    atomic
    {
      if (localEnabled && pMsg->addr != TOS_BCAST_ADDR && ok == FAIL)
      {
        InitCache(idx);
        pMsg->ack = 0;
        busy = FALSE;;
      }
    }
    return ok;
  }
  
  event result_t HWSend.sendDone(TOS_MsgPtr msg, result_t success)
  {
    idx_t idx; //Index 
    bool localEnabled; //Enabled variable for local usage
    
    atomic
    {
      localEnabled = enabled;
      busy = FALSE;
    }
    
    //If we received the ACK message let's NULL the waiting ACK message
    if (msg->type == AM_ACKMSG) 
    {
      atomic
      {
        if (msg == pAckMsg)
          pAckMsg = NULL;
      }
      dbg(DBG_ECC, "ECC: ACK sent to 0x%x\n", msg->addr);
    }

    //If we have no ACK message waiting, let's try to send data message again
    if (pFailedMsg != NULL && pAckMsg == NULL)
    {
      //If there was a failed message
      signal Send.sendDone(pFailedMsg, FAIL);
      dbg(DBG_ECC, "ECC: Queue may resend now 0x%x\n", 
        pFailedMsg->addr);
      atomic
      {
        pFailedMsg = NULL;
      }
    }

    //If we have just sent an ack message - we needn't call the upper level
    if (msg->type == AM_ACKMSG) 
      return SUCCESS;
    
    //If we have a waiting ACK message let's send it anyway
    if (pAckMsg)
    {
      post SendAckTask();
      dbg(DBG_ECC, "ECC: ACK send task scheduled 0x%x -> 0x%x\n",
        pAckMsg->orig, pAckMsg->addr);
    }
      
    if (localEnabled && msg->addr != TOS_BCAST_ADDR)
    {
      // If we failed to send, let's free the slot
      if (success != SUCCESS)
      {
        atomic
        {
          if (FindMsg(msg->token, &idx) == SUCCESS)
            InitCache(idx);
        }
        dbg(DBG_ECC, "ECC: Data send FAILED to 0x%x\n", msg->addr);
        signal Send.sendDone(msg, success);
      }
      else
      {
        atomic
        {
          if (FindMsg(msg->token, &idx) == SUCCESS)
            sentMessages[idx].timeout = DEF_TIMEOUT;
        }
        dbg(DBG_ECC, "ECC: Data sent to 0x%x\n", msg->addr);
      }
    }
    else //If we have just sent the broadcast message - get back
    {
      dbg(DBG_ECC, "ECC: Data sent to 0x%x\n", msg->addr);
      dbg(DBG_ECC, "ECC: Call our senddone for %s\n", 
        (localEnabled) ? "broadcast": "message");
      msg->ack = 1; //we shouldn't care about ACK field in broadcast
      signal Send.sendDone(msg, success);
    }
    return SUCCESS;
  }

  /* 
   * Task used to send ACK for incoming packets
   */
  task void SendAckTask() 
  {
    bool localBusy; //local ack Busy flag
    atomic
    {
      localBusy = busy;
      busy = TRUE; //Set flag to lock ACK sending
    }
    if (!localBusy)
    {
      dbg(DBG_ECC, "ECC: ACK send task running\n");
      call HWSend.send(pAckMsg);
      dbg(DBG_ECC, "ECC: ACK send task finished\n");
    }
  }

  /*
   * ReceiveMsg interface functions
   */
  event TOS_MsgPtr HWReceive.receive(TOS_MsgPtr msg)
  {
    TOS_MsgPtr ret; //temporary return message
    bool localEnabled; //Enabled variable for local usage
    bool localBusy; //If the ACK sending process is started
    uint16_t addr = msg->addr; //Destination address
    uint8_t type = msg->type; //message type
    uint8_t group = msg->group; //message group
    uint8_t token = msg->token; //message token
    uint16_t orig = msg->orig; //Originator's address
    uint16_t localAddress; //local variable containing address
    
    atomic
    {
      localEnabled = enabled;
      localBusy = busy;
      localAddress = TOS_LOCAL_ADDRESS;
    }

    /* We shouldn't send ACKs to ACKs and broadcast messages */

    if (localEnabled && msg->addr == localAddress)
    {
      //Clear out erroneous packets
      if (msg->group != TOS_AM_GROUP || msg->crc != 1)
        return msg;
      if (msg->type == AM_ACKMSG)
      {

        //if we received the ACK message - do upper level call
        idx_t idx; //index of the message in the ACK waiting message array
        if (FindMsg(msg->token, &idx) == SUCCESS)
        {
          sentMessages[idx].pMsg->ack = 1;
          dbg(DBG_ECC, "ECC: ACK received %d 0x%x\n", 
            idx, sentMessages[idx].pMsg->addr);
          signal Send.sendDone(sentMessages[idx].pMsg, SUCCESS);
          InitCache(idx);
        }
        return msg;
      }
      else if (localBusy && pAckMsg)
      {
        //FIXME:  if we unable to send ack we have to discard message, ALAS
        call Leds.redOn();
        dbg(DBG_ECC, "ECC: ACK send task BUSY!!\n");
        return msg;
      }
      call Leds.yellowToggle();
    }

    ret = signal Receive.receive(msg);
    if (ret)
      msg = ret;

    if (localEnabled && addr == localAddress && type != AM_ACKMSG)
    {
      atomic
      {
        pAckMsg = &ackMsg;
        pAckMsg->addr = orig;
        pAckMsg->type = AM_ACKMSG;
        pAckMsg->group = group;
        pAckMsg->length = 0;
        pAckMsg->orig = localAddress;
        pAckMsg->token = token;
      }
      if (!localBusy)
      {
        dbg(DBG_ECC, "ECC: ACK send task scheduled 0x%x -> 0x%x\n",
          pAckMsg->orig, pAckMsg->addr);
        post SendAckTask();
      }
      else
      {
        dbg(DBG_ECC, "ECC: ACK send task DELAYED 0x%x -> 0x%x\n",
          pAckMsg->orig, pAckMsg->addr);
      }
      call Leds.greenToggle();
    }
    return msg;
  }
    
  /*
   * Timer interface functions
   */
  event result_t TimeoutTimer.fired() 
  {
    idx_t i; //index variable
    uint8_t arrEmpty = 1; //If array is empty
    for (i = 0; i < ACK_ARRAY_SIZE; i++)
    {
      if (sentMessages[i].token && sentMessages[i].pMsg)
      {
        arrEmpty = 0; //array is not empty
        if (--sentMessages[i].timeout <= 0)
        {
          /*
           * if timeout - call sendDone with no ack and remove message from
           * array
           */
          sentMessages[i].pMsg->ack = 0;
          dbg(DBG_ECC, "ECC: TIMEOUT OCCURED for %d 0x%x\n", 
            i, sentMessages[i].pMsg->addr);
          call Leds.redOn();
          //Send sendFail signal to upper level
          signal Send.sendDone(sentMessages[i].pMsg, FAIL);
          //Increment the counter of packets to resend for this host
          incResend(sentMessages[i].pMsg->addr);
          //remove the host from list of ACK waiters
          InitCache(i);
        }
      }
    }
    /*
     * If our array is empty we don't neet to check it every time we shall
     * enable timer on message sending
     */
    if (arrEmpty) 
    {
      call Leds.redOff();   
      goTimer(STOP);
    }
    return SUCCESS;
  }

  /* 
   * AttrRegister interface functions
   */
  static inline void setAckEnabler(bool data)
  {
    atomic
    {
        enabled = data;
    }
    if (!data)
    {
      goTimer(STOP);
      //the messages waiting for ACK array will expire when we enable it
      InitMsgArray(); 
      dbg(DBG_ECC, "ECC: ACK usage stopped\n");
    }
    else
    {
      goTimer(START);
      dbg(DBG_ECC, "ECC: ACK usage started\n");
    }
  }

  event result_t Enable.getAttr(char *name, char *resultBuf, 
    SchemaErrorNo *errorNo)
  {
    if (strcmp(name, ACKENABLE) != 0)
    { 
      *errorNo = SCHEMA_ERROR;
    }
    else
    {
      *errorNo = SCHEMA_RESULT_READY;
      atomic
      {
        if (enabled)
          *(uint16_t*)resultBuf = 1;
        else
          *(uint16_t*)resultBuf = 0;
      }
    }
    return SUCCESS;
  }

  event result_t Enable.setAttr(char *name, char *resultBuf)
  {
    bool data = *(uint8_t*)resultBuf; //data to be set
    if (strcmp(name, ACKENABLE) != 0 || (data != 0 && data != 1))
      return FAIL;

      if (data == 0)
        setAckEnabler(FALSE);
      else
        setAckEnabler(TRUE);

    return SUCCESS;
  }

  event result_t Enable.startAttr()
  {
    call Enable.startAttrDone();
    return SUCCESS;
  }
  
  /*
   * CommandRegister functions
   */
  event result_t AckOn.commandFunc(char *commandName, char *resultBuf, 
    SchemaErrorNo *errorNo, ParamVals *params)
  {
    setAckEnabler(TRUE);
    return SUCCESS;
  }

  event result_t AckOff.commandFunc(char *commandName, char *resultBuf, 
    SchemaErrorNo *errorNo, ParamVals *params)
  {
    setAckEnabler(FALSE);
    return SUCCESS;
  }
  /*
   * The NeighTabUpdater interface functions
   */
  command result_t NeighTabUpdater.DelNeigh(uint16_t hostAddr)
  {
    idx_t i; //just the index variable
    if (getIdx(hostAddr, &i) == SUCCESS)
    {
      invalStatCell(i);     
      dbg(DBG_ECC, "ECC: Node %d deleted\n", hostAddr);
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t NeighTabUpdater.AddNeigh(uint16_t hostAddr)
  {
    idx_t freeidx = CHST_ARRAY_SIZE; //index of the first free cell
    //index of the host if host is already in array
    idx_t hostidx = CHST_ARRAY_SIZE; 
    idx_t i; //just the index variable

    for (i = 0; i < CHST_ARRAY_SIZE; i++)
    {
      if (forMote(&chStat[i], hostAddr))
      {
        hostidx = i;
        break; //we found the previous instance of the this host in the array
      }
      if (!(chStat[i].flags & NODE_VALID))
        freeidx = i;
    }
    if (hostidx != CHST_ARRAY_SIZE)
    {
      dbg(DBG_ECC, "ECC: Node %d already present\n", hostAddr);
      return SUCCESS;      
    }
    if (freeidx == CHST_ARRAY_SIZE) //No free cells in the array
      return FAIL;
    chStat[freeidx].addr = hostAddr;
    chStat[freeidx].nResend = 0;
    chStat[freeidx].nRsndCount = 0;
    chStat[freeidx].flags |= NODE_VALID;
    dbg(DBG_ECC, "ECC: Node %d added\n", hostAddr);
    return SUCCESS;
  }

  command result_t NeighTabUpdater.ResetNeigh(uint16_t hostAddr)
  {
    idx_t i; //just the index variable
    if (getIdx(hostAddr, &i) == SUCCESS)
    {
      newStatCell(i);      
      dbg(DBG_ECC, "ECC: Node %d reset\n", hostAddr);
      return SUCCESS;
    }
    return FAIL;
  }

#ifdef _WITH_CHANQ_
  /* 
   * Get the information about channel quality
   */
  command result_t gimme(ChanQMsg* data)
  {
    idx_t i; //Just the index variable. Nothing more
    if (getIdx(data->id, &i) != SUCCESS)
      return FAIL;    
    data->nResend = chStat[i].nResend;
    return SUCCESS;
  }

  /*
   * ChannelQuality timer timeout function
   */
  event result_t CQTimer.fired()
  {
    idx_t i; //just the index variable
    
    for (i = 0; i < CHST_ARRAY_SIZE; i++)
    {
      if (chStat[i].flags & NODE_VALID)
      {
        chStat[i].nResend = chStat[i].nRsndCount;
        chStat[i].nRsndCount = 0;
      }
    }
    dbg(DBG_ECC, "ECC: Resend counter reset\n");
    return SUCCESS;
  }
#endif
}

//eof
