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

	interface Timer;
	
//#if defined(RADIO_CC1000)
    command result_t SetTransmitMode( uint8_t mode );
    interface CC1000Control;
//#endif

    interface Leds;
  }
}
implementation
{
  TOS_Msg buffer; 
  TOS_MsgPtr ourBuffer;
  bool sendPending;
  bool isLowPower;
  uint8_t transmitterNo = 3;
  int16_t deltaT = 0;
  bool TwoAfterOne = TRUE;
  int i;

  void CollisionMsg(TOS_MsgPtr received);
  
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

    dbg( DBG_BOOT, "GenericBase initialized\n" );

    return rcombine3( ok1, ok2, ok3 );
  }


  command result_t StdControl.start()
  {
    result_t ok1, ok2;
    TOSH_SET_PW0_PIN();
	TOSH_SET_PW1_PIN();
    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();

    return rcombine( ok1, ok2 );
  }


  command result_t StdControl.stop()
  {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

	call Timer.stop();
	
    return rcombine( ok1, ok2 );
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
//	set_transmit_mode( 0 );
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
		  //	  call Leds.greenToggle(); //xjiang
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
				  
				  if( fromUART )
					  {
						  // Enable long preamble if forwarding an OnOff message over the radio
						  // that is instructing the motes to turn on.
						  bool enableLP = ((received->type == AM_ONOFF_MSG) && (received->data[0] != 0));
						  enableLongPreamble( enableLP );
//#if defined(RADIO_CC1000)
						  call CC1000Control.SetRFPower( 255 ); //max transmit power
//#endif
						  
						  call Leds.redToggle(); 
						  if (received->type == 109)
							  CollisionMsg(received);
						  else 
							  ok = call RadioSend.send( received );
					  }
				  else
					  {

						  call Leds.greenToggle();
						  // append the signal strength value to the end of the packet
						  // increase the length by sizeof(int) and fill it in with received->strength
						  if (received->type == 102){
							  *((uint16_t *)(&received->data[received->length])) = received->strength;
							  received->length += 2;
						  }
#ifdef ENABLE_UART_DEBUG
 
#else						  
						  ok = call UARTSend.send( received );
#endif
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


  event result_t Timer.fired() {
	  if (TwoAfterOne) {
		  //i = 50;
		  TOSH_CLR_PW1_PIN();
		  //while (i > 0)
		  //  i--;
		  TOSH_SET_PW1_PIN();
	  }
	  else {
		  //i = 50;
		  TOSH_CLR_PW0_PIN();
		  //while (i > 0)
		  //	  i--;
		  TOSH_SET_PW0_PIN();
	  }
	  return SUCCESS;
  }
  
  void CollisionTest(uint8_t transmitter, int16_t dT) {
	  // positive deltaT -> toggle 2 after 1
	  // negative deltaT -> toggle 1 after 2
	  // transmitterNo=3 -> toggle both
	  // transmitterNo=1 -> toggle 1 only
      // transmitterNo=2 -> toggle 2 only
	  // transmitterNo=0 -> toggle none
	  
	  if (transmitter == 3) {
		  if (dT == 0) { // transmit at the same time 
			  i = 50;
			  TOSH_CLR_PW0_PIN();
			  TOSH_CLR_PW1_PIN();
			  //while (i > 0)
			  //  i--;
			  TOSH_SET_PW0_PIN();
			  TOSH_SET_PW1_PIN();
		  }
		  else if (dT > 0) { // 2 after 1
			  TwoAfterOne = TRUE;
			  //i = 50;
			  TOSH_CLR_PW0_PIN();
			  TOSH_SET_PW0_PIN();
			  call Timer.start(TIMER_ONE_SHOT, dT);
		  }
		  else { // 1 after 2
			  TwoAfterOne = FALSE;
			  //i = 50;
			  TOSH_CLR_PW1_PIN();
			  //while (i > 0)
			  //	  i--;
			  TOSH_SET_PW1_PIN();
			  call Timer.start(TIMER_ONE_SHOT, -dT);
		  }
	  }
	  else if (transmitter = 1) { // only 1
		  //i = 50;
		  TOSH_CLR_PW0_PIN();
		  //while (i > 0)
		  //	  i--;
		  TOSH_SET_PW0_PIN();
	  }
	  else if (transmitter = 2) { // only 2
		  //i = 50;
		  TOSH_CLR_PW1_PIN();
		  //while (i > 0)
		  //  i--;
		  TOSH_SET_PW1_PIN();
	  }
	  else // transmit none
		  return;
  }
  
  void CollisionMsg(TOS_MsgPtr data) { // collision msg
	  transmitterNo = data->data[0];
	  deltaT = *((int16_t*)&(data->data[1]));
	  CollisionTest(transmitterNo, deltaT);
  }
  
}  
