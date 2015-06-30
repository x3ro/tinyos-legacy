/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: SimpleTestM.nc,v 1.1 2003/03/19 01:17:56 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * 
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/

#include "BitArraySize.h"

/**
 * Author: Terence Tong
 * This is an example of a general applicaiton using the Routing Stack to send message to
 * basestation. It store a message in its frame, call getUsablePortion to get the right location
 * to add in its own data. passed the data down the stack with the send command. A Send done
 * command will come back. A recomment way to send another message is to have a one shot
 * Time. When the clock fired, we make another attemp to send again
 */

module SimpleTestM {
  provides {
    interface StdControl;
  }
  uses {
    interface VCSend as VCSend1;
    interface Timer as Timer1;
    interface VCSend as VCSend2;
    interface Timer as Timer2;
    interface VCSend as VCSend3;
    interface Timer as Timer3;
    interface Random;
    interface Leds;
    interface BitArray;
  }
}

implementation {

  uint8_t sendBitmapData[BITARRAY_SIZE(11)];
  BitArrayPtr sendBitMap;

#define DATA_FREQ 300
  TOS_Msg msgToSend1;
  TOS_Msg msgToSend2;
  TOS_Msg msgToSend3;

  struct DataFormat_t {
    uint8_t addr;
    uint8_t cnt;
    uint8_t bit1;
    uint8_t bit2;
    uint8_t bit3;
  };
  uint8_t counter1;
  uint8_t counter2;
  uint8_t counter3;

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    int i;
    call Random.init();
    counter1 = 0;
    counter2 = 0;
    counter3 = 0;
    for (i = 0; i < 29; i++) {
      msgToSend1.data[i] = 0;
      msgToSend2.data[i] = 0;
      msgToSend3.data[i] = 0;
    }
    call Timer1.start(TIMER_REPEAT, DATA_FREQ);
    call Timer2.start(TIMER_REPEAT, DATA_FREQ);
    call Timer3.start(TIMER_REPEAT, DATA_FREQ);
		
    call Leds.init();
    sendBitMap = call BitArray.initBitArray(sendBitmapData, BITARRAY_SIZE(11));

    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  void putBitMapOnMsg(TOS_MsgPtr msg) {
    uint8_t i = 0;
    for (i = 0; i < 3; i++) {
      msg->data[i + 4] = call BitArray.readBitInArray(i + 1, sendBitMap);
    }
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * When the clock fired we are ready to send, collectdata ask the stack 
   * where in the data payload we can safely put our data. We then call 
   * Multihop passed the pointer down the stack
   * @author: terence
   * @param: void  
   * @return: always return success
   */
  event result_t Timer1.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;

    if (call BitArray.readBitInArray(1, sendBitMap) == 1) return SUCCESS;

    dataPortion = call VCSend1.getUsablePortion(msgToSend1.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 1;
    df->cnt = counter1++;
		
    call BitArray.saveBitInArray(1, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend1);
    result = call VCSend1.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend1);
    if (result == FAIL) 
      call Leds.yellowOn();
    return SUCCESS;
	
  }

  event void VCSend1.moveOnNextPacket(TOS_MsgPtr msg, uint8_t develivered) {
    call BitArray.saveBitInArray(1, 0, sendBitMap); 
		

  }
  event uint8_t VCSend1.sendDoneFailException(TOS_MsgPtr msg) {
    return 0;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * When the clock fired we are ready to send, collectdata ask the stack 
   * where in the data payload we can safely put our data. We then call 
   * Multihop passed the pointer down the stack
   * @author: terence
   * @param: void  
   * @return: always return success
   */

  event result_t Timer2.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;

    if (call BitArray.readBitInArray(2, sendBitMap) == 1) return SUCCESS;
    dataPortion = call VCSend2.getUsablePortion(msgToSend2.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 2;
    df->cnt = counter2++;
    call BitArray.saveBitInArray(2, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend2);

    result = call VCSend2.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend2);
    if (result == FAIL)
      call Leds.yellowOn();
    return SUCCESS;
	
  }
  event void VCSend2.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(2, 0, sendBitMap); 


  }
  event uint8_t VCSend2.sendDoneFailException(TOS_MsgPtr msg) {
    return 0;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * When the clock fired we are ready to send, collectdata ask the stack 
   * where in the data payload we can safely put our data. We then call 
   * Multihop passed the pointer down the stack
   * @author: terence
   * @param: void  
   * @return: always return success
   */

  event result_t Timer3.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (call BitArray.readBitInArray(3, sendBitMap) == 1) return SUCCESS;
    dataPortion = call VCSend3.getUsablePortion(msgToSend3.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 3;
    df->cnt = counter3++;
    call BitArray.saveBitInArray(3, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend3);

    result = call VCSend3.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend3);
    if (result == FAIL)
      call Leds.yellowOn();
    return SUCCESS;
	
  }
  event void VCSend3.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(3, 0, sendBitMap); 
  }
  event uint8_t VCSend3.sendDoneFailException(TOS_MsgPtr msg) {
    return 0;
  }

}
