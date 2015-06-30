// $Id: TOSBaseM.nc,v 1.1.1.1 2006/05/04 23:08:21 ucsbsensornet Exp $

/*
 * @author Phil Buonadonna
 * @author Gilman Tolle
 * Revision:	$Id: TOSBaseM.nc,v 1.1.1.1 2006/05/04 23:08:21 ucsbsensornet Exp $
 */
  
/* 
 * TOSBaseM bridges packets between a serial channel and the radio.
 * Messages moving from serial to radio will be tagged with the group
 * ID compiled into the TOSBase, and messages moving from radio to
 * serial will be filtered by that same group id.
 */

#ifndef TOSBASE_BLINK_ON_DROP
#define TOSBASE_BLINK_ON_DROP
#endif

includes SimpleCmdMsg;

module TOSBaseM {
  provides interface StdControl;
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;
    interface TokenReceiveMsg as UARTTokenReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface Leds;
    interface Timer as Timer;
  }
}

implementation
{
  enum {
    UART_QUEUE_LEN = 12,
    RADIO_QUEUE_LEN = 12,
  };
  uint8_t 	 MsgType;
  uint16_t	 nsamples;
  uint16_t 	 interval_ms;
  uint16_t 	 netlogseqno;
  uint16_t	 counter;
//  uint16_t	 exp_id;
  TOS_Msg    uartQueueBufs[UART_QUEUE_LEN];
  uint8_t    uartIn, uartOut;
  bool       uartBusy, uartCount;

  TOS_Msg    radioQueueBufs[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioCount;

  task void UARTSendTask();
  task void RadioSendTask();
  
  void StartNodeSensing(struct SimpleCmdMsg *);
  void failBlink();
  void dropBlink();
  void processUartPacket(TOS_MsgPtr Msg, bool wantsAck, uint8_t Token);

  command result_t StdControl.init() {
    result_t ok1, ok2, ok3;

    uartIn = uartOut = uartCount = 0;
    uartBusy = FALSE;

    radioIn = radioOut = radioCount = 0;
    radioBusy = FALSE;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();
    ok3 = call Leds.init();

    dbg(DBG_BOOT, "TOSBase initialized\n");

    return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start() {
    result_t ok1, ok2;

    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();

    return rcombine(ok1, ok2);
  }

  command result_t StdControl.stop() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

    return rcombine(ok1, ok2);
  }

  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr Msg) {

    dbg(DBG_USR1, "TOSBase received radio packet.\n");

    if ((!Msg->crc) || (Msg->group != TOS_AM_GROUP))
      return Msg;

    if (uartCount < UART_QUEUE_LEN) {

      memcpy(&uartQueueBufs[uartIn], Msg, sizeof(TOS_Msg));
      uartCount++;

      if( ++uartIn >= UART_QUEUE_LEN ) uartIn = 0;

      if (!uartBusy) {
	if (post UARTSendTask()) {
	  uartBusy = TRUE;
	}
      }
    } else {
      dropBlink();
    }

    return Msg;
  }
  
  task void UARTSendTask() {
    dbg (DBG_USR1, "TOSBase forwarding Radio packet to UART\n");

    if (uartCount == 0) {

      uartBusy = FALSE;

    } else {

      if (call UARTSend.send(&uartQueueBufs[uartOut]) == SUCCESS) {
//	call Leds.greenToggle();
      } else {
	failBlink();
	post UARTSendTask();
      }
    }
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {

    if (!success) {
      failBlink();
    } else {
      uartCount--;
      if( ++uartOut >= UART_QUEUE_LEN ) uartOut = 0;
    }
    
    post UARTSendTask();

    return SUCCESS;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr Msg) {
    processUartPacket(Msg, FALSE, 0);
    return Msg;
  }

  event TOS_MsgPtr UARTTokenReceive.receive(TOS_MsgPtr Msg, uint8_t Token) {
    processUartPacket(Msg, TRUE, Token);
    return Msg;
  }

  void StartNodeSensing(struct SimpleCmdMsg *cmd) {
    nsamples = cmd->args.ss_args.nsamples;
    interval_ms = cmd->args.ss_args.interval;
    netlogseqno = 0;
    call Timer.start(TIMER_REPEAT, interval_ms);
  }

  void processUartPacket(TOS_MsgPtr Msg, bool wantsAck, uint8_t Token) {
    bool reflectToken = FALSE;
    struct SimpleCmdMsg *cmd = (struct SimpleCmdMsg *)Msg->data;
    dbg(DBG_USR1, "TOSBase received UART token packet.\n");

    if (radioCount < RADIO_QUEUE_LEN) {
      reflectToken = TRUE;

      memcpy(&radioQueueBufs[radioIn], Msg, sizeof(TOS_Msg));

	switch(cmd->action) {
	  case NODE_SENSING:
	    StartNodeSensing(cmd);
	    break;
	  default:	    
	    radioCount++; 
          if( ++radioIn >= RADIO_QUEUE_LEN ) radioIn = 0;
      
          if (!radioBusy) {
	      if (post RadioSendTask()) {
	        radioBusy = TRUE;
	      }
          }
	  }
      } else {
      dropBlink();
    }

    if (wantsAck && reflectToken) {
      call UARTTokenReceive.ReflectToken(Token);
    }
  }
  event result_t Timer.fired() { 
    nsamples--;
    radioCount++;
    if(!radioBusy) {
 	if(post RadioSendTask()) {
	  radioBusy = TRUE;
	}
    }
    if(nsamples == 0) {
 	call Timer.stop();
	return SUCCESS;
    }
    return SUCCESS;
  }

  task void RadioSendTask() {
    struct SimpleCmdMsg *cmd;
    
    dbg(DBG_USR1, "TOSBase forwarding UART packet to Radio\n");
    cmd = (struct SimpleCmdMsg *)radioQueueBufs[radioOut].data;
    if (radioCount == 0) {
      radioBusy = FALSE;
    } else {
      radioQueueBufs[radioOut].group = TOS_AM_GROUP;
	cmd->hop_count = 0;
	cmd->source = TOS_LOCAL_ADDRESS;
	cmd->args.nl_args.netlogseqno = netlogseqno;
      if (call RadioSend.send(&radioQueueBufs[radioOut]) == SUCCESS) {
	  call Leds.redToggle();
	  netlogseqno++;
      } else {
	  failBlink();
	  post RadioSendTask();
      }
    }

  }

  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {

    if (!success) {
      failBlink();
    } else {
      radioCount--;
      if( ++radioOut >= RADIO_QUEUE_LEN ) radioOut = 0;
    }
    
    post RadioSendTask();
    return SUCCESS;
  }

  void dropBlink() {
#ifdef TOSBASE_BLINK_ON_DROP
    call Leds.yellowToggle();
#endif
  }

  void failBlink() {
#ifdef TOSBASE_BLINK_ON_FAIL
    call Leds.yellowToggle();
#endif
  }
}  






// Might need some of this later
/* 
   MsgType = radioQueueBufs[radioIn].data[1];
    if(MsgType == 3)
    {
	netlogseqno = 0;
  	nsamples = radioQueueBufs[radioIn].data[5];
  	nsamples += (256 * radioQueueBufs[radioIn].data[6]);
      interval_ms = radioQueueBufs[radioIn].data[7];
      interval_ms += (256 * radioQueueBufs[radioIn].data[8]);
	call Timer.start(TIMER_REPEAT, interval_ms);
    }
*/
/////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
///Start here creating packet to send to SLTL


/******** Greg's Changes **************
   If the message type is bcast_sensing, retreive the amount
   of samples and intervals
***********************************/
/** Done with Greg's changes **/

