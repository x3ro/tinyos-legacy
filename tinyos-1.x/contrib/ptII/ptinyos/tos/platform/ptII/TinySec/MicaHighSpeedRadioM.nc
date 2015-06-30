// $Id: MicaHighSpeedRadioM.nc,v 1.1 2005/04/19 01:21:21 celaine Exp $

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

// there are awful applications of atomic in here to make warnings go away.
// the main problem is that TinySecM signals some things must by async for
// hardware platforms and then the state vars in this module that get
// updated in those handlers get angry. let me know if you know a
// cleaner, easier way to do it. -chris ckarlof@cs.berkeley.edu

module MicaHighSpeedRadioM
{
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface TinySecRadio;
  }
  uses {
    interface RadioEncoding as Code;
    interface Random;
    interface SpiByteFifo;
    interface ChannelMon;
    interface RadioTiming;
    interface TinySec;
  }
}
implementation
{
  enum { //states
    IDLE_STATE,
    SEND_WAITING,
    HEADER_RX_STATE,
    RX_STATE_TINYSEC,
    RX_STATE,
    TRANSMITTING,
    TRANSMITTING_TINYSEC,
    WAITING_FOR_ACK,
    SENDING_STRENGTH_PULSE,
    TRANSMITTING_START,
    RX_DONE_STATE,
    ACK_SEND_STATE
  };

  enum {
    ACK_CNT = 4,
    ENCODE_PACKET_LENGTH_DEFAULT  = MSG_DATA_SIZE*3
  };


  //static char start[3] = {0xab, 0x34, 0xd5}; //10 Kbps
  //static char start[6] = {0xcc, 0xcf, 0x0f, 0x30, 0xf3, 0x33}; //20 Kbps
  //static char start[12] = {0xf0, 0xf0, 0xf0, 0xff, 0x00, 0xff, 0x0f, 0x00, 0xff, 0x0f, 0x0f, 0x0f}; //40 Kbps

  char state;
  char send_state;
  char tx_count;
  unsigned short calc_crc;
  uint8_t ack_count;
  char rec_count;
  TOS_Msg_TinySecCompat buffer;
  TOS_Msg_TinySecCompat* rec_ptr;
  TOS_Msg_TinySecCompat* send_ptr;
  unsigned char rx_count;
  char msg_length;
  char buf_head;
  char buf_end;
  char encoded_buffer[4];
  char enc_count;
  char decode_byte;
  char code_count;

  short add_crc_byte(char new_byte, short crc);

  bool tx_done;
  bool tinysec_rx_done;

  /**** TinySec ****/
  void swapLengthAndGroup(TOS_Msg* buf) {
    uint8_t tmp = buf->group;

    ((TOS_Msg_TinySecCompat*) buf)->length = buf->length;
    ((TOS_Msg_TinySecCompat*) buf)->group = tmp;

  }
  /**** TinySec ****/
  
  task void packetReceived(){
    TOS_MsgPtr tmp;

    atomic {
      /**** TinySec ****/
      tmp = (TOS_MsgPtr) rec_ptr;
      swapLengthAndGroup(tmp);
      /**** TinySec ****/
      state = IDLE_STATE;
    }
    tmp = signal Receive.receive(tmp);
    if(tmp != 0) {
      atomic {
	rec_ptr = (TOS_Msg_TinySecCompat*) tmp;
      }
    }
    call ChannelMon.startSymbolSearch();
  }

  task void packetSent(){
    RadioMsgSentEvent ev;
    send_state = IDLE_STATE;
    atomic state = IDLE_STATE;
    /**** TinySec ****/
    swapLengthAndGroup((TOS_Msg*) send_ptr);
    /**** TinySec ****/
    memcpy(&ev.message, (TOS_Msg*) send_ptr, sizeof(ev.message));
    sendTossimEvent(NODE_NUM, AM_RADIOMSGSENTEVENT, tos_state.tos_time, &ev);
    signal Send.sendDone((TOS_MsgPtr)send_ptr, SUCCESS);
  }


  command result_t Send.send(TOS_MsgPtr msg) {
    if(send_state == IDLE_STATE){
      /**** TinySec ****/
      swapLengthAndGroup(msg);
      send_ptr = (TOS_Msg_TinySecCompat*) msg;
      /**** TinySec ****/
      send_state = SEND_WAITING;
      atomic tx_done = FALSE;
      tx_count = 1;
      return call ChannelMon.macDelay();
    }else{
      return FAIL;
    }
  }

  /* Command to control the power of the network stack */
  command result_t Control.stop() {
    return SUCCESS;
  }

  command result_t Control.start() {
    return SUCCESS;
  }


  /* Initialization of this component */
  command result_t Control.init() {
    atomic {
      rec_ptr = &buffer;
      send_state = IDLE_STATE;
      state = IDLE_STATE;
    }
    return rcombine(call ChannelMon.init(), call Random.init());
    // TODO:  TOSH_RF_COMM_ADC_INIT();
  } 

  async event result_t TinySec.sendDone(result_t result) {
    atomic {
      tx_done = TRUE;
    }
    return SUCCESS;
  }

  async event result_t TinySec.receiveInitDone(result_t result,
					       uint16_t length,
					       bool ts_enabled) {
    atomic {
      msg_length = length;
      tinysec_rx_done = FALSE;
      if(result == SUCCESS) {
	if(ts_enabled) {
	  dbg(DBG_CRYPTO,"Receive init done TinySec.\n");
	  state = RX_STATE_TINYSEC;
	} else {
	  state = RX_STATE;
	  dbg(DBG_CRYPTO,"Receive init done no TinySec.\n");
	  // set tinysec_rx_done to TRUE to force post of packetReceived
	  // in ACK_SEND_STATE below.
	  tinysec_rx_done = TRUE;
	}
      } else {
	rec_ptr->length = 0;
	state = IDLE_STATE;
      }
    }
    return SUCCESS;
  }

  async event result_t TinySec.receiveDone(result_t result) {
    atomic {
      if(state == RX_DONE_STATE) {
	tinysec_rx_done = TRUE;
	post packetReceived();
      } else {
	tinysec_rx_done = TRUE;
      }
    }
    return SUCCESS;
  }

  // Handles the latest decoded byte propagated by the Byte Level component
  event result_t ChannelMon.startSymDetect() {
    uint16_t tmp;
    atomic {
      ack_count = 0;
      rec_count = 0;
      state = HEADER_RX_STATE;
    }
    dbg(DBG_PACKET, "Detected start symbol.\n");
    tmp = call RadioTiming.getTiming();
    signal RadioReceiveCoordinator.startSymbol(8, 0, (TOS_MsgPtr) rec_ptr);
    /**** TinySec ****/
    atomic call TinySec.receiveInit(rec_ptr);
    /**** TinySec ****/
    return SUCCESS;
  }

  result_t finishedTiming() __attribute__ ((C,spontaneous)) {
    //startReadBytes doesn't do anything with the argument so just passing it 0
    call SpiByteFifo.startReadBytes(0);
    atomic msg_length = MSG_DATA_SIZE - 2;
    calc_crc = 0;
    rec_ptr->time = tos_state.tos_time;
    rec_ptr->strength = 0;
    return SUCCESS;
  }
  
  
  event result_t ChannelMon.idleDetect() {
    if(send_state == SEND_WAITING) {
      buf_end = buf_head = 0;
      enc_count = 0;
      rx_count = 0;
      /**** TinySec ****/
      if(send_ptr->length & TINYSEC_ENABLED_BIT) {
	atomic msg_length = call TinySec.sendInit(send_ptr);
      } else {
	atomic msg_length = (unsigned char)(send_ptr->length) +
	  MSG_DATA_SIZE - DATA_LENGTH - 2;
      }
      /**** TinySec ****/
      send_state = IDLE_STATE;
      atomic state = TRANSMITTING_START;
      call SpiByteFifo.send(TOSH_MHSR_start[0]);
      send_ptr->time = call RadioTiming.currentTime();
      //printf("%i: Sending packet to address 0x%x\n", (int)TOS_LOCAL_ADDRESS, (int)send_ptr->addr);
    }
    signal RadioSendCoordinator.startSymbol(8, 0, (TOS_MsgPtr) send_ptr);
    /**** TinySec ****/
    if(send_ptr->length & TINYSEC_ENABLED_BIT) {
      atomic call TinySec.send();
    }
    /**** TinySec ****/
    
    return 1;
  }

  event result_t Code.decodeDone(char data, char error){
    char stateLocal;
    atomic stateLocal = state;
    
    if(stateLocal == IDLE_STATE){
      return 0;
    } else if (stateLocal == HEADER_RX_STATE) {
      ((char*)rec_ptr)[(int)rec_count] = data;
      rec_count++;
      dbg(DBG_CRYPTO,"Header received byte %d\n",rec_count);
      calc_crc = add_crc_byte(data,calc_crc);
      signal RadioReceiveCoordinator.byte((TOS_MsgPtr) rec_ptr,
					  (uint8_t)rec_count);
      atomic signal TinySecRadio.byteReceived(data);
    }else if(stateLocal == RX_STATE){
      ((char*)rec_ptr)[(int)rec_count] = data;
      rec_count++;
      if(rec_count >= MSG_DATA_SIZE){
	// TODO:  TOSH_RF_COMM_ADC_GET_DATA(0);
	if(calc_crc == rec_ptr->crc){
	  dbg(DBG_CRC, "MicaHighSpeedRadioM: Passed CRC. Expected: 0x%hx, received 0x%hx.\n", calc_crc, rec_ptr->crc);
	  rec_ptr->crc = 1;
	  if(rec_ptr->addr == TOS_LOCAL_ADDRESS ||
	     rec_ptr->addr == TOS_BCAST_ADDR){
	    call SpiByteFifo.send(0x55);
	  }
	}else{
	  dbg(DBG_CRC, "MicaHighSpeedRadioM: Failed CRC. Expected: 0x%hx, received 0x%hx.\n", calc_crc, rec_ptr->crc);
	  rec_ptr->crc = 0;
	}
	atomic state = ACK_SEND_STATE;
        signal RadioReceiveCoordinator.byte((TOS_MsgPtr) rec_ptr,
					    (uint8_t)rec_count);
	return 0;
      }else if(rec_count <= MSG_DATA_SIZE-2){
		  calc_crc = add_crc_byte(data, calc_crc);
      }
      atomic if(rec_count == msg_length){
	rec_count = MSG_DATA_SIZE-2;
      }
    } else if(stateLocal == RX_STATE_TINYSEC) {
      uint8_t rec_count_save = ++rec_count;
      signal RadioReceiveCoordinator.byte((TOS_MsgPtr) rec_ptr,
					  (uint8_t)rec_count);
      atomic signal TinySecRadio.byteReceived(data);
      atomic if(rec_count_save == msg_length + TINYSEC_MAC_LENGTH) {
	if(rec_ptr->crc == 1 &&
	   (rec_ptr->addr == TOS_LOCAL_ADDRESS ||
	   rec_ptr->addr == TOS_BCAST_ADDR)){
	  call SpiByteFifo.send(0x55);
	}
	state = ACK_SEND_STATE;
      }

    }
    return SUCCESS;
  }

  event result_t Code.encodeDone(char data1){
    encoded_buffer[(int)buf_end] = data1;
    buf_end ++;
    buf_end &= 0x3;
    enc_count += 1;
    return SUCCESS;
  }

  event result_t SpiByteFifo.dataReady(uint8_t data) {
    char stateLocal;
    atomic stateLocal = state;
    
    if(stateLocal == TRANSMITTING_START){
      dbg(DBG_PACKET, "Transmitting start symbol, byte %i\n", tx_count);
      call SpiByteFifo.send(TOSH_MHSR_start[(int)tx_count]);
      tx_count ++;
      if(tx_count == sizeof(TOSH_MHSR_start)){
	if(send_ptr->length & TINYSEC_ENABLED_BIT) {
	  char first;
	  atomic first = signal TinySecRadio.getTransmitByte();
	  call Code.encode(first);
	  atomic state = TRANSMITTING_TINYSEC;
	}
	else {
	  char first = ((char*)send_ptr)[0];
	  call Code.encode(first);
	  calc_crc = add_crc_byte(first, 0x00);
	  atomic state = TRANSMITTING;
	}
	tx_count = 1;
      }
    }else if(stateLocal == TRANSMITTING){
      dbg(DBG_PACKET, "Transmitting data, byte %i\n", tx_count);
      call SpiByteFifo.send(encoded_buffer[(int)buf_head]);
      buf_head ++;
      buf_head &= 0x3;
      enc_count --;
      //now check if that was the last byte.

      if(enc_count >= 2){
	;
      }else if(tx_count < MSG_DATA_SIZE){ 
	char next_data = ((char*)send_ptr)[(int)tx_count];
	call Code.encode(next_data);
	tx_count ++;
	atomic if(tx_count <= msg_length){
	  calc_crc = add_crc_byte(next_data, calc_crc);
	}
	atomic if(tx_count == msg_length){
	  //the last 2 bytes must be the CRC and are
	  //transmitted regardless of the length.
	  tx_count = MSG_DATA_SIZE - 2;
	  send_ptr->crc = calc_crc;
	  dbg(DBG_CRC, "MicaHighSpeedRadioM: Send CRC calculated to be 0x%hx.\n", calc_crc);
	}
	signal RadioSendCoordinator.byte((TOS_MsgPtr) send_ptr,
					 (uint8_t)tx_count);
      }else if(buf_head != buf_end){
		  call Code.encode_flush();
      }else{
	atomic state = SENDING_STRENGTH_PULSE;
	tx_count = 0;
      }
    }else if(stateLocal == TRANSMITTING_TINYSEC) {
      dbg(DBG_PACKET, "Transmitting data, byte %i\n", tx_count);
      call SpiByteFifo.send(encoded_buffer[(int)buf_head]);
      buf_head ++;
      buf_head &= 0x3;
      enc_count --;
      //now check if that was the last byte.

      if(enc_count >= 2){
	;
      }else if(tx_count < TINYSEC_MSG_DATA_SIZE){ 
	char next_data;
	atomic next_data = signal TinySecRadio.getTransmitByte();
	call Code.encode(next_data);
	tx_count ++;
	atomic if(tx_done){
	  tx_count = TINYSEC_MSG_DATA_SIZE;
	  dbg(DBG_CRYPTO, "MicaHighSpeedRadioTinySecM: Transmit done.\n");
	}
	signal RadioSendCoordinator.byte((TOS_MsgPtr) send_ptr,
					 (uint8_t)tx_count);
      }else if(buf_head != buf_end){
		  call Code.encode_flush();
      }else{
	atomic state = SENDING_STRENGTH_PULSE;
	tx_count = 0;
      }
    }else if(stateLocal == SENDING_STRENGTH_PULSE){
      tx_count ++;
      dbg(DBG_PACKET, "Transmitting strength pulse, byte %i\n", tx_count);
      if(tx_count == 3){
	atomic state = WAITING_FOR_ACK;
	tx_count = 1;
	call SpiByteFifo.send(0x00);
      }
      else{
	call SpiByteFifo.send(0xff);
      }
    }else if(stateLocal == WAITING_FOR_ACK){
      data &= 0x7f;
      dbg(DBG_PACKET, "Waiting for ACK, byte %i\n", tx_count);
      call SpiByteFifo.send(0x00);
      if(tx_count == 1)
	call SpiByteFifo.phaseShift();
	call SpiByteFifo.rxMode();
      tx_count ++;  
      if(tx_count == ACK_CNT + 2) {
	send_ptr->ack = (data == 0x55);
	dbg(DBG_CRYPTO,"Rcvd ACK %d\n",send_ptr->ack);
	atomic state = IDLE_STATE;
	call SpiByteFifo.idle();
	call ChannelMon.startSymbolSearch();
	post packetSent();
      }
    }else if(stateLocal == RX_STATE ||
	     stateLocal == RX_STATE_TINYSEC ||
	     stateLocal == HEADER_RX_STATE){
      call Code.decode(data);
    }else if(stateLocal == ACK_SEND_STATE){
      dbg(DBG_PACKET, "Sending ACK, count %i\n", (int)ack_count);
      ack_count ++;
      if(ack_count > ACK_CNT + 1){
	atomic state = RX_DONE_STATE;
	call SpiByteFifo.idle();
	atomic if(tinysec_rx_done) {
	  post packetReceived();
	}
      }else{
	 call SpiByteFifo.txMode();
      }
    }
	
    return 1; 
  }

#if 0
  char SIG_STRENGTH_READING(short data){
    rec_ptr->strength = data;
    return 1;
  }
#endif


  short add_crc_byte(char new_byte, short crc){
    uint8_t i;
    crc = crc ^ (int) new_byte << 8;
    i = 8;
    do
      {
	if (crc & 0x8000)
	  crc = crc << 1 ^ 0x1021;
	else
	  crc = crc << 1;
      } while(--i);
    return crc;
  }

  // Default events for radio send/receive coordinators do nothing.
  // Be very careful using these, you'll break the stack.
  default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
  default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) {}
  default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
  default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) {}
}
