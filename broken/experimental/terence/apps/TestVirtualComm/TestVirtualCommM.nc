/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: TestVirtualCommM.nc,v 1.1 2003/03/17 02:04:22 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * 
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/

#include "BitArraySize.h"
//#define CRACY_MODE 1
/**
 * Author: Terence Tong
 * This is an example of a general applicaiton using the Routing Stack to send message to
 * basestation. It store a message in its frame, call getUsablePortion to get the right location
 * to add in its own data. passed the data down the stack with the send command. A Send done
 * command will come back. A recomment way to send another message is to have a one shot
 * Time. When the clock fired, we make another attemp to send again
 */

module TestVirtualCommM {
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
#ifdef CRACY_MODE
    interface VCSend as VCSend4;
    interface Timer as Timer4;
    interface VCSend as VCSend5;
    interface Timer as Timer5;
    interface VCSend as VCSend6;
    interface Timer as Timer6;
    interface VCSend as VCSend7;
    interface Timer as Timer7;
    interface VCSend as VCSend8;
    interface Timer as Timer8;
    interface VCSend as VCSend9;
    interface Timer as Timer9;
    interface VCSend as VCSend10;
    interface Timer as Timer10;

#endif
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

#ifdef CRACY_MODE
  TOS_Msg msgToSend4;
  TOS_Msg msgToSend5;
  TOS_Msg msgToSend6;
  TOS_Msg msgToSend7;
  TOS_Msg msgToSend8;
  TOS_Msg msgToSend9;
  TOS_Msg msgToSend10;
#endif

  struct DataFormat_t {
    uint8_t addr;
    uint8_t cnt;
    uint8_t bit1;
    uint8_t bit2;
    uint8_t bit3;
    uint8_t bit4;
    uint8_t bit5;
    uint8_t bit6;
    uint8_t bit7;
    uint8_t bit8;
    uint8_t bit9;
    uint8_t bit10;
  };
  uint8_t counter1;
  uint8_t counter2;
  uint8_t counter3;

#ifdef CRACY_MODE
  uint8_t counter4;
  uint8_t counter5;
  uint8_t counter6;
  uint8_t counter7;
  uint8_t counter8;
  uint8_t counter9;
  uint8_t counter10;
#endif	
	
  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    int i;
    call Random.init();
    counter1 = 0;
    counter2 = 0;
    counter3 = 0;
#ifdef CRACY_MODE
    counter4 = 0;
    counter5 = 0;
    counter6 = 0;
    counter7 = 0;
    counter8 = 0;
    counter9 = 0;
    counter10 = 0;
#endif
    for (i = 0; i < 29; i++) {
      msgToSend1.data[i] = 0;
      msgToSend2.data[i] = 0;
      msgToSend3.data[i] = 0;
#ifdef CRACY_MODE
      msgToSend4.data[i] = 0;
      msgToSend5.data[i] = 0;
      msgToSend6.data[i] = 0;
      msgToSend7.data[i] = 0;
      msgToSend8.data[i] = 0;
      msgToSend9.data[i] = 0;
      msgToSend10.data[i] = 0;
#endif
    }
    call Timer1.start(TIMER_REPEAT, DATA_FREQ);
    call Timer2.start(TIMER_REPEAT, DATA_FREQ);
    call Timer3.start(TIMER_REPEAT, DATA_FREQ);
#ifdef CRACY_MODE
    call Timer4.start(TIMER_REPEAT, DATA_FREQ);
    call Timer5.start(TIMER_REPEAT, DATA_FREQ);
    call Timer6.start(TIMER_REPEAT, DATA_FREQ);
    call Timer7.start(TIMER_REPEAT, DATA_FREQ);
    call Timer8.start(TIMER_REPEAT, DATA_FREQ);
    call Timer9.start(TIMER_REPEAT, DATA_FREQ);
    call Timer10.start(TIMER_REPEAT, DATA_FREQ);
#endif
		
    call Leds.init();
    sendBitMap = call BitArray.initBitArray(sendBitmapData, BITARRAY_SIZE(11));
															 

    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  void putBitMapOnMsg(TOS_MsgPtr msg) {
    uint8_t i = 0;
    for (i = 0; i < 10; i++) {
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
#ifdef CRACY_MODE
  /*////////////////////////////////////////////////////////*/
  /**
   * When the clock fired we are ready to send, collectdata ask the stack 
   * where in the data payload we can safely put our data. We then call 
   * Multihop passed the pointer down the stack
   * @author: terence
   * @param: void  
   * @return: always return success
   */

  event result_t Timer4.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (call BitArray.readBitInArray(4, sendBitMap) == 1) return SUCCESS;
    dataPortion = call VCSend4.getUsablePortion(msgToSend4.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 4;
    df->cnt = counter4++;
    call BitArray.saveBitInArray(4, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend4);

    result = call VCSend4.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend4);

    return SUCCESS;
	
  }
  event void VCSend4.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(4, 0, sendBitMap); 
  }
  event uint8_t VCSend4.sendDoneFailException(TOS_MsgPtr msg) {
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

  event result_t Timer5.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (call BitArray.readBitInArray(5, sendBitMap) == 1) return SUCCESS;

    dataPortion = call VCSend5.getUsablePortion(msgToSend5.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 5;
    df->cnt = counter5++;
    call BitArray.saveBitInArray(5, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend5);

    result = call VCSend5.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend5);

    return SUCCESS;
	
  }
  event void VCSend5.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(5, 0, sendBitMap); 
  }
  event uint8_t VCSend5.sendDoneFailException(TOS_MsgPtr msg) {
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

  event result_t Timer6.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (call BitArray.readBitInArray(6, sendBitMap) == 1) return SUCCESS;
    dataPortion = call VCSend6.getUsablePortion(msgToSend6.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 6;
    df->cnt = counter6++;
    call BitArray.saveBitInArray(6, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend6);

    result = call VCSend6.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend6);

    return SUCCESS;
	
  }
  event void VCSend6.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(6, 0, sendBitMap); 
  }
  event uint8_t VCSend6.sendDoneFailException(TOS_MsgPtr msg) {
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

  event result_t Timer7.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (call BitArray.readBitInArray(7, sendBitMap) == 1) return SUCCESS;
    dataPortion = call VCSend7.getUsablePortion(msgToSend7.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 7;
    df->cnt = counter7++;
    call BitArray.saveBitInArray(7, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend7);

    result = call VCSend7.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend7);

    return SUCCESS;
	
  }
  event void VCSend7.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(7, 0, sendBitMap); 
  }
  event uint8_t VCSend7.sendDoneFailException(TOS_MsgPtr msg) {
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

  event result_t Timer8.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (call BitArray.readBitInArray(8, sendBitMap) == 1) return SUCCESS;
    dataPortion = call VCSend8.getUsablePortion(msgToSend8.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 8;
    df->cnt = counter8++;
    call BitArray.saveBitInArray(8, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend8);

    result = call VCSend8.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend8);

    return SUCCESS;
	
  }
  event void VCSend8.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(8, 0, sendBitMap); 
  }
  event uint8_t VCSend8.sendDoneFailException(TOS_MsgPtr msg) {
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

  event result_t Timer9.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (call BitArray.readBitInArray(9, sendBitMap) == 1) return SUCCESS;
    dataPortion = call VCSend9.getUsablePortion(msgToSend9.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 9;
    df->cnt = counter9++;
    call BitArray.saveBitInArray(9, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend9);

    result = call VCSend9.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend9);

    return SUCCESS;
	
  }
  event void VCSend9.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(9, 0, sendBitMap); 
  }
  event uint8_t VCSend9.sendDoneFailException(TOS_MsgPtr msg) {
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

  event result_t Timer10.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (call BitArray.readBitInArray(10, sendBitMap) == 1) return SUCCESS;
    dataPortion = call VCSend10.getUsablePortion(msgToSend10.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = 10;
    df->cnt = counter10++;
    call BitArray.saveBitInArray(10, 1, sendBitMap); 
    putBitMapOnMsg(&msgToSend10);

    result = call VCSend10.send(TOS_UART_ADDR, sizeof(struct DataFormat_t), &msgToSend10);

    return SUCCESS;
	
  }
  event void VCSend10.moveOnNextPacket(TOS_MsgPtr msg, uint8_t delivered) {
    call BitArray.saveBitInArray(10, 0, sendBitMap); 
  }
  event uint8_t VCSend10.sendDoneFailException(TOS_MsgPtr msg) {
    return 0;
  }

#endif

}
