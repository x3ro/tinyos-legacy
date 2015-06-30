/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 *    Author: Chris Karlof
 *    Date:   1/24/03
 */
module MicaHighSpeedRadioTinySecM
{
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
  }
  uses {
    interface RadioEncoding as Code;
    interface Random;
    interface SpiByteFifo;
    interface ChannelMon;
    interface RadioTiming;
    interface TinySec;
    interface BlockCipherInfo;
  }
}
implementation
{
  enum { //states
    IDLE_STATE,
    SEND_WAITING,
    RX_STATE,
    TRANSMITTING,
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
  // The C attribute is used here because we are not currently supporting
  // intialisers on module variables (because tossim makes it tricky)
  char TOSH_MHSR_start[12] __attribute((C)) = 
    {0xf0, 0xf0, 0xf0, 0xff, 0x00, 0xff, 0x0f, 0x00, 0xff, 0x0f, 0x0f, 0x0f}; //40 Kbps

  char state;
  char send_state;
  char tx_count;
  uint8_t ack_count;
  char rec_count;
  TOS_Msg buffer;
  TOS_Msg* rec_ptr;
  TOS_Msg* send_ptr;
  unsigned char rx_count;
  char msg_length;
  char buf_head;
  char buf_end;
  char encoded_buffer[4];
  char enc_count;
  char decode_byte;
  char code_count;

  // TinySec buffers
  TinySec_Msg tinysec_rec_buffer;
  TinySec_Msg tinysec_send_buffer;
  bool decrypt_done;
  uint8_t mac_rec_count;
  uint8_t decrypt_rec_count;
  uint8_t blockSize;
  
  task void packetReceived(){
    // The ACK must be sent and the packet decrypted before it is signaled to the top layers.
    // The below condition checks for both.
    if(decrypt_done && state == RX_DONE_STATE) {
      TOS_MsgPtr tmp = NULL;
      state = IDLE_STATE;
      // Packet is not signaled up if MAC fails.
      if(tinysec_rec_buffer.validMAC) {
	rec_ptr->addr = tinysec_rec_buffer.addr;
	// Group is no longer supported. TinySec sets group to 0.
	rec_ptr->group = 0;
	rec_ptr->length = tinysec_rec_buffer.length;
	rec_ptr->type = tinysec_rec_buffer.type;
	// Zero out padding added at send time.
	if(call TinySec.removePadding(rec_ptr)) {
	  tmp = signal Receive.receive((TOS_Msg*)rec_ptr);
	}
      }
      decrypt_done = FALSE;
      tinysec_rec_buffer.computeMACDone = FALSE;
      tinysec_rec_buffer.validMAC = FALSE;
      if(tmp != 0) {
	rec_ptr = tmp;
      }
      call ChannelMon.startSymbolSearch();
    }
  }
  
  task void packetSent(){
    send_state = IDLE_STATE;
    state = IDLE_STATE;
    call ChannelMon.startSymbolSearch();
    signal Send.sendDone((TOS_MsgPtr)send_ptr, SUCCESS);
  }

  command result_t Send.send(TOS_MsgPtr msg) {
    if(send_state == IDLE_STATE){
      send_state = SEND_WAITING;
      tx_count = 1;
      send_ptr = msg;
      tinysec_send_buffer.addr = send_ptr->addr;
      tinysec_send_buffer.length = send_ptr->length;
      tinysec_send_buffer.type = send_ptr->type;
      if(!(call TinySec.preparePadding(send_ptr))) {
	return FAIL;
      }
      return call ChannelMon.macDelay();
    } else {
      return FAIL;
    }
  }
  
  /* Initialization of this component */
  command result_t Control.init() {
    rec_ptr = &buffer;
    tinysec_rec_buffer.validMAC = FALSE;
    tinysec_rec_buffer.computeMACDone = FALSE;
    decrypt_done = FALSE;
    send_state = IDLE_STATE;
    state = IDLE_STATE;
    blockSize = call BlockCipherInfo.getPreferredBlockSize();
    return rcombine(call ChannelMon.init(), call Random.init());
    // TODO:  TOSH_RF_COMM_ADC_INIT();
  } 

  /* Command to control the power of the network stack */
  command result_t Control.start() {
    return SUCCESS;
  }

  /* Command to control the power of the network stack */
  command result_t Control.stop() {
    return SUCCESS;
  }

  event result_t TinySec.computeMACDone(result_t result, TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr)   {
    return SUCCESS;
  }

  event result_t TinySec.encryptDone(result_t result, TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr) {
    if(result)
      return call TinySec.computeMAC(cleartext_ptr,ciphertext_ptr);
    else
      return FAIL;
  }
  
  event result_t TinySec.decryptDone(result_t result, TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr) {
    decrypt_done = TRUE;
    post packetReceived();
    return SUCCESS;
  }

  // Handles the latest decoded byte propagated by the Byte Level component
  event result_t ChannelMon.startSymDetect() {
    uint16_t tmp;
    ack_count = 0;
    rec_count = 0;
    mac_rec_count = 0;
    decrypt_rec_count = 0;
    state = RX_STATE;
    tmp = call RadioTiming.getTiming();
    call SpiByteFifo.startReadBytes(tmp);
    msg_length = TINYSEC_MSG_DATA_SIZE - TINYSEC_MAC_LENGTH;
    rec_ptr->time = tmp;
    rec_ptr->strength = 0;
    tinysec_rec_buffer.validMAC = FALSE;
    tinysec_rec_buffer.computeMACDone = FALSE;
    return SUCCESS;
  }


  event result_t ChannelMon.idleDetect() {
    if(send_state == SEND_WAITING){
      char first = ((char*)&tinysec_send_buffer)[0];
      buf_end = buf_head = 0;
      enc_count = 0;
      call Code.encode(first);
      rx_count = 0;
      if(((unsigned char)(tinysec_send_buffer.length)) < blockSize) {
	msg_length = blockSize + TINYSEC_MSG_DATA_SIZE - DATA_LENGTH - TINYSEC_MAC_LENGTH;
      } else {
	msg_length = (unsigned char)(tinysec_send_buffer.length) + TINYSEC_MSG_DATA_SIZE - DATA_LENGTH - TINYSEC_MAC_LENGTH;
      }
      send_state = IDLE_STATE;
      state = TRANSMITTING_START;
      call SpiByteFifo.send(TOSH_MHSR_start[0]);
      send_ptr->time = call RadioTiming.currentTime();
      if(!(call TinySec.encrypt(send_ptr,&tinysec_send_buffer))) {
	return FAIL;
      }
    }
    return 1;
  }

  event result_t Code.decodeDone(char data, char error){
    if(state == IDLE_STATE){
      return 0;
    }else if(state == RX_STATE){
      ((char*)&tinysec_rec_buffer)[(int)rec_count] = data;
      rec_count++;
      mac_rec_count++;
      if(rec_count >= TINYSEC_ENCRYPTED_DATA_BEGIN_BYTE_NUMBER && rec_count <= msg_length) {
	decrypt_rec_count++;
      }

      // this assumes that TINYSEC_LENGTH_BYTE_NUMBER < blockSize
      if(rec_count == TINYSEC_LENGTH_BYTE_NUMBER){
	if(((unsigned char)data) < DATA_LENGTH){
	  if((unsigned char)data < blockSize) {
	    // min length is blockSize
	    msg_length = blockSize + TINYSEC_MSG_DATA_SIZE - DATA_LENGTH - TINYSEC_MAC_LENGTH;
	  } else {
	    // set msg_length to length of packet - MAC length
	    msg_length = ((unsigned char)data) + TINYSEC_MSG_DATA_SIZE - DATA_LENGTH - TINYSEC_MAC_LENGTH;
	  }
	} else {
          // length field is too long. shorten it to max. this is likely a bad packet.
          tinysec_rec_buffer.length = DATA_LENGTH;
	}
	// Need to init MAC computation. Re-enable interrupts inside verifyMAC init and then call MAC.init.
	call TinySec.computeMACIncrementalInit(&tinysec_rec_buffer);
	return SUCCESS;
      }
      
      // we have reached the end of the data part of packet. jump to end of buffer to receive MAC
      if(rec_count == msg_length){
	uint8_t rec_count_save = rec_count;
	rec_count = TINYSEC_MSG_DATA_SIZE-TINYSEC_MAC_LENGTH;
	call TinySec.computeMACIncremental(&tinysec_rec_buffer,rec_count_save-mac_rec_count,mac_rec_count);
	call TinySec.computeMACIncrementalFinish(&tinysec_rec_buffer);
	call TinySec.decryptIncremental(&tinysec_rec_buffer,rec_ptr,rec_count_save-decrypt_rec_count-TINYSEC_ENCRYPTED_DATA_BEGIN_BYTE_NUMBER+1,decrypt_rec_count);
	return SUCCESS;
      }

      if(rec_count < msg_length) {
	bool decrypt_needed = (decrypt_rec_count == blockSize);
	uint8_t rec_count_save = rec_count;
	if(mac_rec_count == blockSize) {
	  mac_rec_count = 0;
	  call TinySec.computeMACIncremental(&tinysec_rec_buffer,rec_count-blockSize,blockSize);
	}
	// cant use rec_count here. might have changed since computeMACIncremental was done.
	if(rec_count_save == TINYSEC_END_OF_IV_BYTE_NUMBER) {
	  call TinySec.decryptIncrementalInit(&tinysec_rec_buffer);
	} else if(decrypt_needed) {
	  decrypt_rec_count -= blockSize;
	  call TinySec.decryptIncremental(&tinysec_rec_buffer,rec_ptr,rec_count_save-blockSize-TINYSEC_ENCRYPTED_DATA_BEGIN_BYTE_NUMBER+1,blockSize);
	}
	return SUCCESS;
      }

      if(rec_count >= TINYSEC_MSG_DATA_SIZE){
	call TinySec.verifyMAC(&tinysec_rec_buffer);
	if(tinysec_rec_buffer.validMAC) {
	  rec_ptr->crc = 1;
	  if(tinysec_rec_buffer.addr == TOS_LOCAL_ADDRESS ||
	     tinysec_rec_buffer.addr == TOS_BCAST_ADDR){
	    call SpiByteFifo.send(0x55);
	  } 
	}else{
	  rec_ptr->crc = 0;
	}
	state = ACK_SEND_STATE;
	return SUCCESS;
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
    if(state == TRANSMITTING_START){
      call SpiByteFifo.send(TOSH_MHSR_start[(int)tx_count]);
      tx_count ++;
      if(tx_count == sizeof(TOSH_MHSR_start)){
	state = TRANSMITTING;
	tx_count = 1;
      }
    }else if(state == TRANSMITTING){
      call SpiByteFifo.send(encoded_buffer[(int)buf_head]);
      buf_head ++;
      buf_head &= 0x3;
      enc_count --;
      
      //now check if that was the last byte.
      if(enc_count >= 2){
	;
      }else if(tx_count < TINYSEC_MSG_DATA_SIZE){ 
	char next_data = ((char*)&tinysec_send_buffer)[(int)tx_count];
	call Code.encode(next_data);
	tx_count ++;

	if(tx_count == msg_length){
	  tx_count = TINYSEC_MSG_DATA_SIZE - TINYSEC_MAC_LENGTH;
	}
	
      }else if(buf_head != buf_end){
	call Code.encode_flush();
      }else{
	state = SENDING_STRENGTH_PULSE;
	tx_count = 0;
      }
    }else if(state == SENDING_STRENGTH_PULSE){
      tx_count ++;
      if(tx_count == 3){
	state = WAITING_FOR_ACK;
	call SpiByteFifo.phaseShift();
	tx_count = 1;
	call SpiByteFifo.send(0x00);
	
      }else{
	call SpiByteFifo.send(0xff);
      }
    }else if(state == WAITING_FOR_ACK){
      data &= 0x7f;
      call SpiByteFifo.send(0x00);
      if(tx_count == 1) {
	call SpiByteFifo.rxMode();
      }
      tx_count ++;  
      if(tx_count == ACK_CNT + 2) {
	send_ptr->ack = (data == 0x55);
	state = IDLE_STATE;
	call SpiByteFifo.idle();
	post packetSent();
      }
    }else if(state == RX_STATE){
      call Code.decode(data);
    }else if(state == ACK_SEND_STATE){
      ack_count ++;
      if(ack_count > ACK_CNT + 1){
	state = RX_DONE_STATE;
	call SpiByteFifo.idle();
	post packetReceived();
      }else{
	 call SpiByteFifo.txMode();
      }
    }
	
    return SUCCESS; 
  }

#if 0
  char SIG_STRENGTH_READING(short data){
    rec_ptr->strength = data;
    return 1;
  }
#endif

}
