/*
 * @author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: jan05
 *
 * provides timestamping on transmitting/receiving SFD interrupt.
 */

#include "AM.h"

module ClockTimeStampingM
{
    provides
    {
        interface TimeStamping;
    }
    uses
    {
        interface RadioCoordinator as RadioSendCoordinator;
        interface RadioCoordinator as RadioReceiveCoordinator;
        interface LocalTime;
        interface Leds;
        interface HPLCC2420RAM;
    }
}

implementation
{
    // the offset of the time-stamp field in the message, 
    // or -1 if no stamp is necessariy.
    norace int8_t sendStampOffset = -1;
    uint32_t rcv_time;
    
    enum{
        TX_FIFO_MSG_START = 10,
        SEND_TIME_CORRECTION = 1,
    };
        
    async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
    {
        uint32_t send_time;
        atomic send_time = call LocalTime.read() - SEND_TIME_CORRECTION;
        call Leds.redToggle();
                
        if( sendStampOffset < 0 )
            return;

        *(uint32_t*)((void*)msgBuff->data + sendStampOffset) += send_time;

        call HPLCC2420RAM.write(TX_FIFO_MSG_START + sendStampOffset, 4, (void*)msgBuff->data + sendStampOffset);
        sendStampOffset = -1;   
    }

    async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
    {
            atomic rcv_time = call LocalTime.read();
            call Leds.greenToggle();
    }

    command uint32_t TimeStamping.getStamp()
    {
        uint32_t tmp;
        atomic tmp=rcv_time;
        return tmp;
    }


    //this needs to be called right after SendMsg.send() returned success, so 
    //the code in addStamp() method runs before a task in the radio stack is 
    //posted that writes to fifo -> which triggers coordinator event 
    
    //if a msg is already being served by the radio, (sendStampOffset is 
    //defined), timestamping returns fail

    command result_t TimeStamping.addStamp(int8_t offset)
    {
        if(sendStampOffset<0 && 0 <= offset && offset <= TOSH_DATA_LENGTH-4 ){
            atomic sendStampOffset = offset;
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

}
