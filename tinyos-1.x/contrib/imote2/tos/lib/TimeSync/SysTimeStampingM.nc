/*
 * @author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: jan05
 *
 * provides timestamping on transmitting/receiving SFD interrupt,uses 
 * SysTime (Timer3) to get local time 
 */

#include "AM.h"

module SysTimeStampingM
{
	provides
	{
		interface TimeStamping;
	}
	uses
	{
		interface RadioCoordinator as RadioSendCoordinator;
		interface RadioCoordinator as RadioReceiveCoordinator;
		interface SysTime64;
		interface Leds;
		interface HPLCC2420RAM;
	}
}

implementation
{
	// the offset of the time-stamp field in the message, 
	// or -1 if no stamp is necessariy.
	norace int8_t sendStampOffset = -1;
    norace int8_t sendStampOffsetHigh = -1;
	uint32_t rcv_time, send_time, rcv_timeHigh, send_timeHigh;
	norace TOS_MsgPtr ptosMsg;
	
    enum{
        TX_FIFO_MSG_START = 10,
        SEND_TIME_CORRECTION = -2300,
    };
        
	async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
	{
        int32_t temp;
        uint8_t i, *ptr, *srcPtr, *dstPtr;
		if (ptosMsg != 0 && ptosMsg != msgBuff)
			return; 

		//atomic send_time = call SysTime.getTime32()  - SEND_TIME_CORRECTION;
		atomic call SysTime64.getTime64(&send_time, &send_timeHigh);
        //temp = *(int32_t*)((void*)msgBuff->data+sendStampOffset);
        ptr = &msgBuff->data;
        //trace(DBG_USR1,"sendOff=%d  sendOffHi=%d\r\n",sendStampOffset,sendStampOffsetHigh);

        memcpy(&temp,ptr+sendStampOffset,4);

        send_time += temp;
        //temp = *(int32_t*)((void*)msgBuff->data+sendStampOffsetHigh);
        ptr = &msgBuff->data;
        memcpy(&temp,ptr+sendStampOffsetHigh,4);

        send_timeHigh += temp;

		//call Leds.redToggle();
				
		if( sendStampOffset < 0 )
			return;

        /* *(uint32_t*)((void*)msgBuff->data + sendStampOffset) += send_time;
	    *(uint32_t*)((void*)msgBuff->data + sendStampOffsetHigh) += send_timeHigh;
	    send_time = *(uint32_t*)((void*)msgBuff->data + sendStampOffset);
	    send_timeHigh = *(uint32_t*)((void*)msgBuff->data + sendStampOffsetHigh);*/

		//call HPLCC2420RAM.write(TX_FIFO_MSG_START + sendStampOffset, 8, (void*)msgBuff->data + sendStampOffset);
		call HPLCC2420RAM.write(TX_FIFO_MSG_START + sendStampOffset, 4, &send_time);
		call HPLCC2420RAM.write(TX_FIFO_MSG_START + sendStampOffsetHigh, 4, &send_timeHigh);
		sendStampOffset = -1;	
        //trace (DBG_USR1,"send_time: %x\r\n",send_time);

	}
    
    task void postPrintRcvTime(){
        trace (DBG_USR1,"rcv_time: %x\r\n",rcv_time);
    }
    
	async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
	{
        atomic {
            call SysTime64.getTime64(&rcv_time, &rcv_timeHigh);
        }
        //call Leds.greenToggle();
        //post postPrintRcvTime();
	}

	command result_t TimeStamping.getStamp(uint32_t *tLow, uint32_t *tHigh)
	{
	    atomic {
            *tLow=rcv_time;
            *tHigh=rcv_timeHigh;
        }
		return SUCCESS;
	}
    /*
    command uint32_t TimeStamping.getSendTime() {
	    uint32_t tmp;
	    atomic tmp=send_time;
		return tmp;
	}
    */  


    //this needs to be called right after SendMsg.send() returned success, so 
    //the code in addStamp() method runs before a task in the radio stack is 
    //posted that writes to fifo -> which triggers coordinator event 
    
    //if a msg is     already being served by the radio, (sendStampOffset is 
    //defined),     timestamping returns fail
    /*
	command result_t TimeStamping.addStamp(int8_t offset)
	{
		if(sendStampOffset<0 && 0 <= offset && offset <= TOSH_DATA_LENGTH-4 ){
			atomic sendStampOffset = offset;
			ptosMsg = 0;
			return SUCCESS;
		}
		else
			sendStampOffset = -1;
		
		return FAIL;
	}
    */

	command result_t TimeStamping.addStamp2(TOS_MsgPtr msg, int8_t offset, int8_t offsetHigh)
	{
		if(sendStampOffset<0 && 0 <= offset && offset <= TOSH_DATA_LENGTH-4 ){
			atomic {
                sendStampOffset = offset;
                sendStampOffsetHigh = offsetHigh;
            }
			ptosMsg = msg;
			return SUCCESS;
		}
		else
			sendStampOffset = -1;
		
		return FAIL;
	}
    
    async event result_t HPLCC2420RAM.readDone(uint16_t addr, uint8_t length, uint8_t* buffer){
        return SUCCESS;
    }
    
    async event result_t HPLCC2420RAM.writeDone(uint16_t addr, uint8_t length, uint8_t* buffer){
        return SUCCESS;
    }
    async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
    async event void RadioSendCoordinator.blockTimer() { }

    async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
    async event void RadioReceiveCoordinator.blockTimer() { }

    async event result_t SysTime64.alarmFired(uint32_t val) { }
}
