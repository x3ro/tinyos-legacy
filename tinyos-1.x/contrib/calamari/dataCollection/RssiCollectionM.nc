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
 */

/* Authors:   Kamin Whitehouse
 *
 */

includes RssiCollection;
includes Rpc;

module RssiCollectionM {
 provides interface StdControl;
 uses interface StdControl as TimerControl;
 uses interface SendMsg as SendChirpMsg;
 uses interface ReceiveMsg as ReceiveChirpMsg;
 uses interface CC2420Control as CCControl;
 uses interface Timer;
 uses interface Leds;
 uses interface Mount;
 uses interface BlockRead;
 uses interface Straw;
 provides command result_t chirp(uint8_t chirpPower, uint8_t numberOfChirps, uint16_t period) @rpc();
}

implementation {
  uint8_t chirpPower;
  uint8_t nonChirpingPower;
  uint8_t powerSent;
  uint8_t numberOfChirps; 
  uint16_t period; 

  uint8_t msgNumber; 
  //  uint8_t state;
  bool sending;

  uint16_t data[BUFFER_SIZE];
  uint16_t dataPos;

  TOS_Msg msg;
  ChirpMsg *chirpMsg;

  command result_t StdControl.init()
  {
    //    state=IDLE;
    sending = FALSE;
    dataPos=0;
    call TimerControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Mount.mount(RSSI_LOG_ID);
    call TimerControl.start(); 
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop(); 
    call TimerControl.stop(); 
    return SUCCESS;
  }

  void recordMsg(uint16_t addr, uint16_t id, uint16_t rssi, uint16_t lqi){
    if ( dataPos < BUFFER_SIZE-4){
      data[dataPos++] = addr;
      data[dataPos++] = id;
      data[dataPos++] = rssi;
      data[dataPos++] = lqi;
    }
  }

  event TOS_MsgPtr ReceiveChirpMsg.receive(TOS_MsgPtr p_msg)
  {
    ChirpMsg* m = (ChirpMsg*)p_msg->data;
    recordMsg(m->transmitterId, m->msgNumber, p_msg->strength, p_msg->lqi);
    return p_msg;
  }

  command result_t chirp(uint8_t p_chirpPower, uint8_t p_numberOfChirps, uint16_t p_period)
  {
    msgNumber=0;
    chirpPower = p_chirpPower;
    numberOfChirps = p_numberOfChirps;
    period = p_period;
    //    state = CHIRPING;
    call Leds.greenOn();
    return call Timer.start(TIMER_REPEAT, period);
  }

  task void chirpTask(){
    if( msgNumber>=numberOfChirps){
      //      state = IDLE;
      call Timer.stop();
      call Leds.greenOff();
      return;
    }
    if (sending==TRUE) return;
    nonChirpingPower= call CCControl.GetRFPower();

    call CCControl.SetRFPower(chirpPower);
    chirpMsg = (ChirpMsg*)(&(msg.data));
    chirpMsg->transmitterId=TOS_LOCAL_ADDRESS;
    chirpMsg->msgNumber=msgNumber;
    chirpMsg->rfPower=call CCControl.GetRFPower();

    if(call SendChirpMsg.send(TOS_BCAST_ADDR, sizeof(ChirpMsg), &msg)==SUCCESS){          
      sending=TRUE;
      powerSent = call CCControl.GetRFPower();
     call Leds.redToggle(); 
    } else {
      call Leds.yellowToggle();
    }
  }
  
  void task readSuccess() {
    call Straw.readDone(SUCCESS);
  }

  event void Mount.mountDone(storage_result_t result, volume_id_t id) {
  }

  event void BlockRead.readDone(storage_result_t result, block_addr_t addr,
    void* buf, block_addr_t len) {
    call Straw.readDone(result == STORAGE_OK ? SUCCESS : FAIL);
  }
  event void BlockRead.verifyDone(storage_result_t result) {
  }
  event void BlockRead.computeCrcDone(storage_result_t result, uint16_t crc,
    block_addr_t addr, block_addr_t len) {
  }

  event result_t Straw.read(uint32_t start, uint32_t size, uint8_t* returnBffr) {
    //    return call BlockRead.read(start, bffr, size);
    uint8_t i;
    for (i = 0; i < size; i++) {
      returnBffr[i] = ((uint8_t*)data)[start + i];
    }
    post readSuccess();
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    //    if(state==CHIRPING) {  
      post chirpTask();
      //    }
    return SUCCESS;
  }

  event result_t SendChirpMsg.sendDone(TOS_MsgPtr m, result_t success)
  {
    call CCControl.SetRFPower(nonChirpingPower);
    if (success == SUCCESS){
      recordMsg(TOS_LOCAL_ADDRESS, msgNumber++, powerSent, 0);
    }
    sending=FALSE;
    return SUCCESS;
  }

}








