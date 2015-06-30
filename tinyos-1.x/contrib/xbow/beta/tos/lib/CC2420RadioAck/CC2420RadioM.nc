// $Id: CC2420RadioM.nc,v 1.6 2004/12/02 18:30:50 jdprabhu Exp $

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
 *  Authors: Joe Polastre, Matt Miller-Crossbow

CC2420RadioM (Ack Version)
Provides standard CC2420 Radio stack for IEEE 802.15.4 with "manual" software
 message acknowledgement. Permits promiscuous listening in reliable-route 
 applications plus message acknowledgement. Functional equivalent to MICA2 
 CC1000RadioAck services.

 *  Date last modified: $Revision: 1.6 $
 * $Id: CC2420RadioM.nc,v 1.6 2004/12/02 18:30:50 jdprabhu Exp $
 */

/**
 * @author Joe Polastre
 * @author Alan Broad, Crossbow
 */

includes byteorder;

module CC2420RadioM {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface MacControl;
    interface MacBackoff;
    interface RadioPower;
  }
  uses {
    interface StdControl as CC2420StdControl;
    interface CC2420Control;
    interface HPLCC2420 as HPLChipcon;
    interface HPLCC2420FIFO as HPLChipconFIFO; 
    interface StdControl as TimerControl;

    interface TimerJiffyAsync as BackoffTimerJiffy;
    interface Random;
    interface Leds;
  }
}

implementation {
#define SEND_RETRY_COUNT 8	//number of backoffs during send for a clear channel before giving up
  enum {
    DISABLED_STATE=0,
    IDLE_STATE,
    PRE_TX_STATE,
    TX_STATE,
    POST_TX_STATE,
    RX_STATE,
	RX_ACK_STATE,
    POWER_DOWN_STATE,
	TIMER_IDLE = 0,
    TIMER_INITIAL,
    TIMER_BACKOFF,
    TIMER_ACK
  };




typedef struct CC2420_MsgAck
{
  uint8_t length;
  uint8_t fcfhi;
  uint8_t fcflo;
  uint8_t dsn;
} CC2420_MsgAck;

  norace uint8_t stateTimer;

  uint8_t RadioState;
  uint8_t bRxBufLocked;
  uint8_t currentDSN;
  bool bAckEnable;
  bool bAckManual;
  uint16_t txlength;
  uint16_t rxlength;
  TOS_MsgPtr txbufptr;  // pointer to transmit buffer
  TOS_MsgPtr rxbufptr;  // pointer to receive buffer
  TOS_Msg RxBuf;	// save received messages
  uint8_t cnttryToSend;

  // XXX-PB:
  // Here's the deal, the mica (RFM) radio stacks used TOS_LOCAL_ADDRESS
  // to determine if an L2 ack was reqd.  This stack doesn't do L2 acks
  // and, thus doesn't need it.  HOWEVER, some set-mote-id versions
  // break if this symbol is missing from the binary.
  // Thus, I put this LocalAddr here and set it to TOS_LOCAL_ADDRESS
  // to keep things happy for now.
  volatile uint16_t LocalAddr;

  ///**********************************************************
  //* local function definitions
  //**********************************************************/

void fSendAborted(); 
uint8_t fTXPacket(uint8_t len, uint8_t* pMsg );

   inline result_t setInitialTimer( uint16_t jiffy ) {
     stateTimer = TIMER_INITIAL;
     return call BackoffTimerJiffy.setOneShot(jiffy);
   }

   inline result_t setBackoffTimer( uint16_t jiffy ) {
     stateTimer = TIMER_BACKOFF;
     return call BackoffTimerJiffy.setOneShot(jiffy);
   }

   inline result_t setAckTimer( uint16_t jiffy ) {
     stateTimer = TIMER_ACK;
//	call Leds.redOn();		   //wait done
     return call BackoffTimerJiffy.setOneShot(jiffy);
   }



/**
************************************************************************/
bool GetRegs() 
  {
  
  uint16_t data;
  uint8_t i;

  for (i=CC2420_MAIN;i<CC2420_RESERVED ;i++ )
    {
    data = call HPLChipcon.read(i);
//	dbg(1,"CC2420Reg[x%x]=x%x \n",i,data);
    }
  }

/******************************************************************************
 * PacketRcvd
 * - Radio packet rcvd, signal 
 *****************************************************************************/
   task void PacketRcvd() {
    TOS_MsgPtr pBuf;
    //could get here while a TX msg is being processed

    atomic {
      rxbufptr->time = 0;
      pBuf = rxbufptr;
	  if(RadioState == RX_ACK_STATE ){
 		while (TOSH_READ_CC_SFD_PIN()){};  // wait until SFD pin goes low - tx actually finished
	     RadioState = IDLE_STATE; 
	  }
    }
    pBuf = signal Receive.receive((TOS_MsgPtr)pBuf);
    atomic {
      if (pBuf) rxbufptr = pBuf;
      rxbufptr->length = 0;
	  bRxBufLocked = FALSE; //now available for use
    }
//debug - reenable FIFOP interrupts now	we have a valid rxbuf
	call HPLChipcon.enableFIFOP();


  }

  
task void PacketSent() {
    TOS_MsgPtr pBuf; //store buf on stack 
    uint8_t currentstate;
    atomic currentstate = RadioState;
	if( (currentstate==POST_TX_STATE) ) 
	  {
	    atomic {
	      RadioState = IDLE_STATE;
	      txbufptr->time = 0;
	      pBuf = txbufptr;
		  //restore Payload length field as provided by caller
	      pBuf->length = pBuf->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
		  }
 		while (TOSH_READ_CC_SFD_PIN()){};  // wait until SFD pin goes low - tx actually finished
		signal Send.sendDone(pBuf,SUCCESS);  //cnttryToSend==0 if timedout
    } //if POST_TX_STATE
	//else this task invocation is a duplicate, ignore
   return;
  }

  ///**********************************************************
  //* Exported interface functions
  //**********************************************************/
/**
************************************************************************************/
  command result_t StdControl.init() {

    atomic {
      RadioState = DISABLED_STATE;
      currentDSN = 0;
      bAckEnable = FALSE;
      bAckManual = TRUE;
      rxbufptr = &RxBuf;
      rxbufptr->length = 0;
      rxlength = MSG_DATA_SIZE-2; //includes length byte, not FCS
    }

    call CC2420StdControl.init();
    call TimerControl.init();
    call Random.init();
    LocalAddr = TOS_LOCAL_ADDRESS;

    call MacControl.disableAck();	//disables address decode also
    call MacControl.disableAddrDecode(); //and enables Manual Ack


    return SUCCESS;
  }
/**
************************************************************************************/
  command result_t StdControl.stop() {
    atomic RadioState = DISABLED_STATE;

    call TimerControl.stop();
    call CC2420StdControl.stop();
    return SUCCESS;
  }
/**
************************************************************************************/
  command result_t StdControl.start() {
    uint8_t chkRadioState;

    atomic chkRadioState = RadioState;

    if (chkRadioState == DISABLED_STATE) {
      atomic {
			rxbufptr->length = 0;
			RadioState  = IDLE_STATE;

			call TimerControl.start();
			call CC2420StdControl.start();  // PRESENT STRATEGY WILL WAIT ~2 msec
			call CC2420Control.RxMode();
 //		GetRegs();
      }//atomic
    }	//DISABLED
    return SUCCESS;
  }

/**
Abort Send operation because cannot get a clear channel
******************************************************************************/
void fSendAborted() 
  {
    TOS_MsgPtr pBuf; //store buf on stack 
	uint8_t currentstate;

	//CLEANUP the CC2420
           call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
           call HPLChipcon.cmd(CC2420_SFLUSHRX);
           call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
           call HPLChipcon.cmd(CC2420_SFLUSHRX);

	  //route to correct caller
	  atomic currentstate=RadioState;
	  if( (currentstate >= PRE_TX_STATE) && (currentstate<=POST_TX_STATE) )
		  {	 //in a TX sequence
		  atomic
		    {
	      	txbufptr->time = 0;
			pBuf = txbufptr;
			//restore Payload length field as provided by caller
			pBuf->length = pBuf->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
			RadioState = IDLE_STATE;
		    }
	      signal Send.sendDone(pBuf,FAIL); //this could hang things up
		  }

	//check if this is required ????
	call HPLChipcon.enableFIFOP();	 
	 return;
  }
/**
Transmit contents of TXFIFO.
If no clear channel, backoff and try again
If transmit works
	if sent a manual Ack then post the received message
	if sent a std msg
		enable RX Interrupts
		if AckMode start Ack timer and wait
		else post SendDone
*********************************************************************************/


  result_t sendPacket() {
    uint8_t status;
    uint16_t fail_count = 0;
	uint8_t currentstate;

    call HPLChipcon.cmd(CC2420_STXONCCA);
    status = call HPLChipcon.cmd(CC2420_SNOP);
    if ((status >> CC2420_TX_ACTIVE) & 0x01) {
		//tx started
      while (!TOSH_READ_CC_SFD_PIN()){
	fail_count ++;
	TOSH_uwait(5);
	if(fail_count > 1000){
        	fSendAborted();
		return(FAIL);	
	}
      };  // wait until SFD pin goes high

		atomic currentstate = RadioState;	//exit based different states
		switch( currentstate ) {

		case PRE_TX_STATE:
		case TX_STATE:		   
			atomic RadioState = POST_TX_STATE;
			call HPLChipcon.enableFIFOP();	//receive interrupt back on

			txbufptr->ack = 1;	 //implicit acknowledge
			if ( (bAckEnable || bAckManual) &&(txbufptr->addr != TOS_BCAST_ADDR)){
				txbufptr->ack = 0;	 //no ack yet
				while (TOSH_READ_CC_SFD_PIN()){};  // wait until SFD pin goes low - tx finished

				if( (setAckTimer(2*CC2420_ACK_DELAY)) )  //slower than autoack
					return(SUCCESS);	//now wait for an ack
				}//if bAckMode

			// Here if nonAck mode or AckWait start failed
			if( !post PacketSent() ) 
				{fSendAborted();return(FAIL);} //post FAIL
			break; //ok

		default:	 //unexpected state	??? Add better recovery - dont want send to hang	
			atomic RadioState = IDLE_STATE;
			call HPLChipcon.enableFIFOP();	//just incase turn interrupt back on
			return(FAIL);//send FAIL
			break;
		}//switch
	return(SUCCESS); //	
    }	//if status==txstarted
    else {
      if (!(setBackoffTimer(signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT))) {
        fSendAborted();
      }
    }//else - try send again
	return(SUCCESS);	//function completed - tx done or retry started
  }//sendPacket
/*********************************************************************************/

/**
*********************************************************************************/
  void tryToSend() {
     uint8_t currentstate;
     atomic currentstate = RadioState;

     // and the CCA check is good
     if (currentstate == PRE_TX_STATE || currentstate == TX_STATE) {
       if (TOSH_READ_RADIO_CCA_PIN()) {
		atomic RadioState = TX_STATE;	//new state to inhibit duplicate SendPackets
		call HPLChipcon.disableFIFOP();	 
		sendPacket();
       }
       else {
         if (cnttryToSend-- <= 0) {
           fSendAborted();
           return;
         }
         if (!(setBackoffTimer(signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT))) {
           fSendAborted();
         }
       }
     }
  }


/**
*******************************************************************************/
  async event result_t BackoffTimerJiffy.fired() {
    uint8_t cret;
    uint8_t currentstate;
    atomic currentstate = RadioState;

//	call Leds.redOff();		   //transmit done
    switch (stateTimer) {
    case TIMER_INITIAL:
		stateTimer = TIMER_IDLE; 
		//Disable RX Interrupts - maybe able to move this to writeTXFIFO time
 		call HPLChipcon.disableFIFOP();	 

		cret = fTXPacket(txlength+1, (uint8_t*)txbufptr );		//handles actual packet transmission
		if( !cret ){  //fail means did not complete,  has it been aborted??
			atomic RadioState = IDLE_STATE; //senddone doesnt happen
		}
		call HPLChipcon.enableFIFOP();  //note fTXPacket also enablesFIFOP iff it gets far enuf
      break;
    case TIMER_BACKOFF:
		stateTimer = TIMER_IDLE; 
      tryToSend();
      break;
    case TIMER_ACK:
		stateTimer = TIMER_IDLE; 
      if (currentstate == POST_TX_STATE) {
        txbufptr->ack = 0;
     //   post PacketSent();
		if(!post PacketSent()) {
			//		call AckTimerJiffy.setOneShot(CC2420_ACK_DELAY); //so try again later..
			fSendAborted(); //abort
			}
      }
      break;
    }
    return SUCCESS;
  }
/*************************************************************************************/



/** fTXPacket
	Load TXFIFO with 15.4 MACPDU, start transmit, and do finishup (ACK etc) routing
	Assumes CC2420 RXInterrupt disabled. 
	EnablesInterrupts if tx succeeds, does not handle correctly on error- this needs to be managed.
	Starts an ACKTimer if in TX_STATE and AckEnabled
	If successfull posts packetSent or packetReceived
	returns SUCCESS or FAIL
****************************************************************************************/
result_t fTXPacket(uint8_t len, uint8_t* pMsg ) 
{
		
		//loadup TXFIFO with message
		if (!(call HPLChipcon.cmd(CC2420_SFLUSHTX)))
		  	return(FAIL); //send FAIL
		//load txfifo, 
      if( !(len = call HPLChipconFIFO.writeTXFIFO(len,(uint8_t*)pMsg)) ) 
		  	return(FAIL);//send FAIL

	return(sendPacket()); //sent or retrying
}//fTXPacket

 /**********************************************************
   * Send
   * - Xmit a packet
   *    USE SFD FALLING FOR END OF XMIT !!!!!!!!!!!!!!!!!! interrupt???
   * - If in power-down state start timer ? !!!!!!!!!!!!!!!!!!!!!!!!!s
   * - If !TxBusy then 
   *   a) Flush the tx fifo 
   *   b) Write Txfifo address
   *    
   **********************************************************/
  command result_t Send.send(TOS_MsgPtr pMsg) {
	 uint8_t cntRetry;
	 uint8_t cret;
    uint8_t currentstate;
    atomic currentstate = RadioState;


    if (currentstate == IDLE_STATE) {
      	// put default FCF values in to get address checking to pass
      	pMsg->fcflo = CC2420_DEF_FCF_LO;
      	if (bAckEnable) 
        	pMsg->fcfhi = CC2420_DEF_FCF_HI_ACK;
      	else 
        	pMsg->fcfhi = CC2420_DEF_FCF_HI;
      	// destination PAN is broadcast
      	pMsg->destpan = TOS_BCAST_ADDR;
      	// adjust the destination address to be in the right byte order
      	pMsg->addr = toLSB16(pMsg->addr);
      	// adjust the  length (for TXFIFO MPDU) to the full packet length+space for FCS(footer)
	  // MSG_HEADER_SIZE is MHR - does NOT include length byte. Nominally 7bytes
      	pMsg->length = pMsg->length + MSG_HEADER_SIZE + MSG_FOOTER_SIZE; //with 2 xtra FSC bytes
      	// keep the DSN increasing for ACK recognition
      	pMsg->dsn = ++currentDSN;
      	// FCS bytes generated by CC2420
      	txlength = pMsg->length - MSG_FOOTER_SIZE;  //this is the actual CC2420 PAYLOAD( MHR+MPDU)length (w/o FCS)
 
	atomic txbufptr = pMsg;

	//Disable RX Interrupts - maybe overkill but prevents RX from overloading timer
	 //	call HPLChipcon.disableFIFOP();	 

	atomic {
		RadioState = PRE_TX_STATE; //race
	}
      	if (setInitialTimer(signal MacBackoff.initialBackoff(txbufptr) * CC2420_SYMBOL_UNIT)) {
		cnttryToSend = SEND_RETRY_COUNT;
        	return SUCCESS;
      	}
	//here if failed so restore RadioState
	atomic RadioState = IDLE_STATE; //race
	call HPLChipcon.enableFIFOP();	 

    }//if idle
    return(FAIL);
  }//.send

/**
	Send ACK in response to received message
---------------------------------------------------------------------*/
result_t fsendAck(uint8_t ReceivedDSN) {
	result_t cret = FAIL;
	uint8_t currentstate;
	CC2420_MsgAck AckBuff;
	CC2420_MsgAck * pAck = &AckBuff;
	uint8_t len;

	atomic currentstate = RadioState;

    if (currentstate == RX_ACK_STATE) {  //acknowldge
		// put default FCF values in to get address checking to pass
		pAck->length = sizeof(struct CC2420_MsgAck)-1+ MSG_FOOTER_SIZE;   //minus length byte plus add 2 fCS
		pAck->fcfhi = CC2420_DEF_FCF_TYPE_ACK;
		pAck->fcflo = 0x00;  //all other bits 0 in an ACK Frame
		// keep the DSN increasing for ACK recognition
		pAck->dsn = ReceivedDSN;
		//number of bytes to be passed to TXFIFO
		len = pAck->length - MSG_FOOTER_SIZE + 1;	//+1 is the first (length) byte itself

		//loadup TXFIFO with message
		cret = call HPLChipcon.cmd(CC2420_SFLUSHTX);
		//load txfifo, 
      	cret = call HPLChipconFIFO.writeTXFIFO(len,(uint8_t*)pAck);
			
		if(!cret)
			return(cret);
	//	transmit ACK packet - no retries
	    call HPLChipcon.cmd(CC2420_STXONCCA);
	    cret = call HPLChipcon.cmd(CC2420_SNOP);
	    if ((cret >> CC2420_TX_ACTIVE) & 0x01) {
		//tx started
			rxbufptr->ack = TRUE;		//indicates an acknowldge was sent
			cret = post PacketRcvd() ;

		} else cret = FAIL;// ack TX didnt start

	} //currentstate=RX_ACK
	return cret;	 //wrong state
}	//fSendAck

  /**********************************************************
   * FIFOP lo Interrupt: Rx data avail in CC2420 fifo
   * Radio must have been in Rx mode to get this interrupt
   * If FIFO pin =lo then fifo overflow=> flush fifo & exit
   * 
   *
   * Things ToDo:
   *
   * -Disable FIFOP interrupt until PacketRcvd task complete 
   * or until send.done complete
   *
   * -Fix mixup: on return
   *  rxbufptr->rssi is CRC + Correlation value
   *  rxbufptr->strength is RSSI
   **********************************************************/
   async event result_t HPLChipcon.FIFOPIntr() {

	result_t cret;
	uint8_t *pData;
	uint8_t length = MSG_DATA_SIZE;	//total size of available buffer -including length byte
	uint8_t currentstate;
	atomic currentstate = RadioState;


	//THIS SECTION SHOULD NOT HAPPEN W/INT DISABLED DURING PRE_TX
	//if we're trying to send a message and a FIFOP interrupt occurs
	// and acks are enabled, we need to backoff longer so that we don't
	// interfere with the AUTOMATIC  ACK

	if ( (bAckEnable) && (currentstate == PRE_TX_STATE)) {
	 if (call BackoffTimerJiffy.isSet()) {
	   call BackoffTimerJiffy.stop();
	   call BackoffTimerJiffy.setOneShot((signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT) + CC2420_ACK_DELAY);
	 }
	}

       // FLush FIFO if overflowed
       if (!TOSH_READ_CC_FIFO_PIN() || bRxBufLocked){
	   //	GetRegs();
           call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
           call HPLChipcon.cmd(CC2420_SFLUSHRX);
//---           call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
           call HPLChipcon.cmd(CC2420_SFLUSHRX);
           return FAIL;
        }

/* New code */
        // Read first byte and header bytes of FIFO - the packet length byte
	// atomic bRxBufLocked=TRUE;	//rxbuffer is now busy
	pData = (uint8_t *) rxbufptr;
	length = call HPLChipconFIFO.readRXFIFO(1, pData);

        //ignore msb, length is size of MPDU
	rxbufptr->length &= CC2420_LENGTH_MASK;	

        //number of bytes in packet - excluding length byte
	length = rxbufptr->length;	 

        //Test - is length reasonable?
        //If too long or too short, flush FIFO and exit
	// if ((length > MSG_DATA_SIZE - 1) || (length<MSG_ACK_SIZE - 1)){
	if ((length > MSG_DATA_SIZE - 1)){
            call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
            call HPLChipcon.cmd(CC2420_SFLUSHRX);
//--            call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
            call HPLChipcon.cmd(CC2420_SFLUSHRX);
	    atomic bRxBufLocked=FALSE;	//rxbuffer is now free
	    return FAIL;
        }





        // Read remainder of packet
	pData = (uint8_t *) rxbufptr+1;	  //read into rxbuffer following the length byte
	length = call HPLChipconFIFO.readRXFIFO(length, pData);
	//note pData is 1byte into rxbufptr and length is 1 byte smaller 'cause doesnotinclude lengthbyte
//--Check CRC	- reject if bad 
	if( !(pData[length-1] & 0x80) )	{
		atomic bRxBufLocked=FALSE;	//rxbuffer is free
		return SUCCESS;		 //not a DATA packet type - discard
	 }
//---
	//Process Ack Message related to a Transmission
	if( ((rxbufptr->fcfhi & 0x03) == CC2420_DEF_FCF_TYPE_ACK) && (rxbufptr->dsn == currentDSN) )
		if( (bAckEnable || bAckManual) && (currentstate == POST_TX_STATE) ) { //only if expecting an ack 	 
			txbufptr->ack = 1;
			if( post PacketSent()) 
				call BackoffTimerJiffy.stop();	 //clear the AckWDT
			return SUCCESS;				 //all done
	    }
	//Throw out anything other than Data Packets
    if ((rxbufptr->fcfhi & 0x03) != CC2420_DEF_FCF_TYPE_DATA){
		atomic bRxBufLocked=FALSE;	//rxbuffer is free
		return SUCCESS;		 //not a DATA packet type - discard
	 }

//Ackit
//	if( bAckManual )
//      call HPLChipcon.cmd(CC2420_SACK);


	atomic bRxBufLocked=TRUE;	//rxbuffer is now busy
	//adjust length to reflect TOS PAYLOAD length, MSG_HEADER_SIZE=MHR+TOSHeader=12
	rxbufptr->length = rxbufptr->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;

	// adjust destination to the right byte order
	rxbufptr->addr = fromLSB16(rxbufptr->addr);

	// FCS/MFR last 2 bytes:FCS[0]=RSSI, FCS[1]=CRCWeighted,MSB=CRCOK
	rxbufptr->crc = pData[length-1] >> 7;  //MSBit is CRCOK
	// just put in RSSI for now, calculate LQI later
	rxbufptr->strength = pData[length-2];
	rxbufptr->ack = FALSE;	//default is not acknowledged

	//Send an Acknowledge  iff appropriate	
	//what if we are in middle of a TX send sequence? -throw out ack for now
	if( bAckManual ){
//		if( rxbufptr->addr == TOS_LOCAL_ADDRESS || rxbufptr->addr == TOS_BCAST_ADDR){  
		if( (rxbufptr->addr == TOS_LOCAL_ADDRESS) &&  (rxbufptr->group == TOS_AM_GROUP) ){  
     		 call HPLChipcon.cmd(CC2420_SACK);
             while (!TOSH_READ_CC_SFD_PIN()){};  // wait until SFD pin goes high -sending ack
           }//addr	
		}//backmanual

    while (TOSH_READ_CC_SFD_PIN()){};  // wait until SFD pin goes low - tx actually finished

 	//packet received and done
 	if(!post PacketRcvd()) atomic bRxBufLocked=FALSE;  

	return SUCCESS;
}//FIFOPIntr

//----------------------------------------------------------------------------------
/** Parse Received MAC Protocol Data Unit (MPDU) from CC2420.
MPDU buffer contents returned in RXFIFODone
[0] length/MPDU datasize (excluding length byte, including MFR-CRC&RSSI bytes)
[1..8] MHR Header=FCF(2)+SEQ(1)+PANDest(2)+Addr(2)=7
[9..] Payload=TOSMessage
[ln-1] crc
[ln] rssi 


@param length Total number of bytes read from RXFIFO
@param data buffer pointer 
****************************************************************************************/
  async event result_t HPLChipconFIFO.RXFIFODone(uint8_t length, uint8_t *data) {
	//stub - do nothing
	return(SUCCESS);
	}

//----------------------------------------------------------------------------------
/** TX FIFO has been loaded with Packet, now try to send it.
*************************************************************************************/
  async event result_t HPLChipconFIFO.TXFIFODone(uint8_t length, uint8_t *data) {
  //do nothing - replaced by a function
  return(SUCCESS);
  }
  /**
  Enable CC2420 Receiver Hardware Address Decode.
  ************************************************************/
  async command void MacControl.enableAddrDecode() {
    call CC2420Control.enableAddrDecode();
	bAckManual = TRUE;
  }
  /**
  Disable CC2420 Receiver Hardware Address Decode.
  Also disables AutoAck - no ack without Address decode
  ************************************************************/
  async command void MacControl.disableAddrDecode() {
    call CC2420Control.disableAddrDecode();
    call CC2420Control.disableAutoAck();  //AutoAck not valid w/o Address decode
    bAckManual = TRUE;	  //enable promiscuous Ack
  }

  async command void MacControl.enableAck() {
    bAckEnable = TRUE;
	bAckManual = FALSE;
    call CC2420Control.enableAutoAck();
  }

  async command void MacControl.disableAck() {
    bAckEnable = FALSE;

    call CC2420Control.disableAutoAck();
  }

  /**
   * How many basic time periods to back off.
   * Each basic time period consists of 20 symbols (16uS per symbol)
   */
  default async event int16_t MacBackoff.initialBackoff(TOS_MsgPtr m) {
    return ((call Random.rand() & 0xF) + 1);
  }
  /**
   * How many symbols to back off when there is congestion (16uS per symbol)
   */
  default async event int16_t MacBackoff.congestionBackoff(TOS_MsgPtr m) {
    return ((call Random.rand() & 0xF) + 1);
  }

// Default events for radio send/receive coordinators do nothing.
// Be very careful using these, you'll break the stack.
default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }


command result_t RadioPower.SetTransmitMode(uint8_t power) {
  return SUCCESS;
}

command result_t RadioPower.SetListeningMode(uint8_t power) {
  return SUCCESS;
}

}





