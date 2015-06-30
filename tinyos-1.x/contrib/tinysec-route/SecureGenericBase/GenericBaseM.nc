/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

includes DefineCC1000;
includes onoff;
includes rt2;
includes TinySecControl;

module GenericBaseM
{
  provides interface StdControl;
  uses
  {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface TinySecMode;
    
//#if defined(RADIO_CC1000)
    command result_t SetTransmitMode( uint8_t mode );
    interface CC1000Control;
//#endif

    //  interface Timer;
    interface Time;
    interface Leds;
  }
}
implementation
{
  TOS_Msg buffer; 
  TOS_MsgPtr ourBuffer;
  bool sendPending;
  bool isLowPower;

  /*
  uint8_t state;
  uint32_t out;
  uint32_t in;
  TOS_Msg timeMsg;
  */
  
  void set_transmit_mode( uint8_t mode )
  {
//#if defined(RADIO_CC1000)
    call SetTransmitMode( mode );
//#endif
  }


  command result_t StdControl.init()
  {
    result_t ok1, ok2, ok3;

    ourBuffer = &buffer;
    sendPending = TRUE;
    isLowPower = FALSE;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();
    ok3 = call Leds.init();

    sendPending = FALSE;

    set_transmit_mode(0);

    call TinySecMode.setReceiveMode(TINYSEC_RECEIVE_ANY);
//   call TinySecMode.setTransmitMode(TINYSEC_ENCRYPT_AND_AUTH);
    dbg( DBG_BOOT, "GenericBase initialized\n" );

//    state = 0;
    
    return rcombine3( ok1, ok2, ok3 );
  }


  command result_t StdControl.start()
  {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();

//    call Timer.start(TIMER_REPEAT,1024);
    
    return rcombine( ok1, ok2 );
  }


  command result_t StdControl.stop()
  {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

    return rcombine( ok1, ok2 );
  }

  /*
  task void report() {
    timeMsg.type = 50;
    timeMsg.length = 8;
    timeMsg.group = 0xdd;
    memcpy(timeMsg.data,&out,4);
    memcpy(timeMsg.data+4,&in,4);
    call Leds.yellowToggle();
    call UARTSend.send( &timeMsg );
  }
  
  event result_t Timer.fired() {
    if(state == 0) {
      out = call Time.getLow32();
      state = 1;
    } else { // (state = 1) 
      in = call Time.getLow32();
      state = 0;
      post report();
    }
    return SUCCESS;
  }
  */
  
  void setTSMode(bool configTS, TOS_MsgPtr received)
  {
  
   if (configTS)
       {
          switch (received->data[0]) {
             
          case TRANSMIT:
                  call TinySecMode.setTransmitMode(received->data[1]);
                  
          case RECEIVE: 
                 call TinySecMode.setReceiveMode(received->data[1]); 
                
          default:
                 // do nothing for now -- eventually raise an error or dbg message
          } 
  
    }
  }
  
  void enableLongPreamble( bool enable )
  {
    if( enable != isLowPower )
    {
      isLowPower = enable;
      if( enable )
      {
    call Leds.yellowOn();
//#if defined(RADIO_CC1000)
    set_transmit_mode( CC1K_LPL_STATES-1 );
//#else
//  set_transmit_mode( 0 );
//#endif
      }
      else
      {
    call Leds.yellowOff();
    set_transmit_mode( 0 );
      }
    }
  }


  TOS_MsgPtr receive( TOS_MsgPtr received, bool fromUART )
  {
    TOS_MsgPtr nextReceiveBuffer = received;
    RebroadcastCmd * cmd; 
    
    dbg( DBG_USR1, "GenericBase received %s packet\n",
    fromUART ? "UART" : "radio" );

    if( (!sendPending)
        && (received->group == (TOS_AM_GROUP & 0xff) || TOS_AM_GROUP == 255)
      )
    {
      result_t ok = FAIL;
      
      nextReceiveBuffer = ourBuffer;
      ourBuffer = received;
      dbg( DBG_USR1, "GenericBase forwarding packet to %s\n",
                     fromUART ? "radio" : "UART" );

      cmd = (( RebroadcastCmd*)received->data);
      if(received->type == 100 && /* cory's routing layer */
	 received->data[received->length - 1] == RT_CMD_MSG_HANDLER && /* real AM */
	 received->data[0] == RT2MCD_ROUTE &&
	 received->data[2] == RT2A_BCAST) {
/*         cmd->cmd.cmd == RT2MCD_ROUTE &&
	   cmd->cmd.action.action == RT2A_BCAST) {*/
	uint32_t time = call Time.getLow32();
	memcpy(received->data + 4, /*&cmd->cmd.action.timestampout,*/&time,4);
      }
      if(received->type == 102 && /* Cory's routing am */
	 received->data[received->length -1]  == RT_ANSWER_HANDLER) {
	uint32_t time = call Time.getLow32();
        struct RT2AnswerMsg  * msg= (struct RT2AnswerMsg *)received->data;
        // should be 5 bytes in.
        memcpy(&msg->timestampin, &time, 4);
      }
      
      if( fromUART )
      {
    // Enable long preamble if forwarding an OnOff message over the radio
    // that is instructing the motes to turn on.
    bool enableLP = ((received->type == AM_ONOFF_MSG) && (received->data[0] != 0));
    bool configTS = ((received->type == AM_TINYSEC_CONTROL) && (received->data[0] != 0));
    
    enableLongPreamble( enableLP );
    setTSMode(configTS, received); 
    if(configTS)
      return nextReceiveBuffer;
    
//#if defined(RADIO_CC1000)
    call CC1000Control.SetRFPower( 255 ); //max transmit power
//#endif
    call Leds.redToggle();
    ok = call RadioSend.send( received );
      }
      else
      {
    call Leds.greenToggle();
    ok = call UARTSend.send( received );
      }

      if( ok != FAIL )
      {
    dbg( DBG_USR1, "GenericBase send pending\n" );
    sendPending = TRUE;
      }
      else
      {
    //call Leds.yellowToggle();
      }
      
    }
    return nextReceiveBuffer;
  }
  
  result_t sendDone( TOS_MsgPtr sent, result_t success )
  {
    //call Leds.redOn();
    if( ourBuffer == sent )
    {
      dbg( DBG_USR1, "GenericBase send buffer free\n" );
      //if( success == FAIL ) call Leds.yellowToggle();
      sendPending = FALSE;
    }
    return SUCCESS;
  }
  
  event TOS_MsgPtr RadioReceive.receive( TOS_MsgPtr data )
  {
    if( data->crc )
      return receive( data, FALSE );
    return data;
  }
  
  event TOS_MsgPtr UARTReceive.receive( TOS_MsgPtr data )
  {
    TOS_AM_GROUP = data->group;
    return receive( data, TRUE );
  }
  
  event result_t UARTSend.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return sendDone( msg, success );
  }
  
  event result_t RadioSend.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return sendDone( msg, success );
  }
}  
