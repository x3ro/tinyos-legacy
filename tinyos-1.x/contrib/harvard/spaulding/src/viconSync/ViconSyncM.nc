/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/**                                                                                  
 * Description - Synchronizes FTSP motes with Vicon motion capture system.
 * 
 * @author Konrad Lorincz
 * @version 1.0 - August 24, 2006
 */
#include "PrintfUART.h"
#include "ViconSync.h"
#include "ViconSyncMsg.h"

module ViconSyncM                                        
{
    provides interface StdControl;

    uses interface Leds;
    uses interface SendMsg;
    uses interface ReceiveMsg;
    uses interface Timer as Timer_RisingEdge;
    uses interface Timer as Timer_FallingEdge;
    uses interface GlobalTime;
}
implementation
{
    // ========================= Data =========================
    enum {TIMER_RISINGEDGE_INTERVAL = 5000L,
          TIMER_FALLINGEDGE_INTERVAL = 500L};
    uint16_t edgeCnt = 0;

    TOS_Msg tosSendMsg;
    ViconSyncMsg* vsMsgPtr;
    bool tosSendMsgBusy = FALSE;


//     void sendMsg(TOS_Msg *sendMsgPtr, uint16_t sendAddr, uint8_t dataSize);


    // ========================= Methods =========================
    void stopPulses()
    {
        atomic {
            call Timer_RisingEdge.stop();
            call Leds.greenOff();
        }
    }

    void startPulses()
    {
        atomic {
            stopPulses();

            edgeCnt = 0;
            call Timer_RisingEdge.start(TIMER_REPEAT, TIMER_RISINGEDGE_INTERVAL);   
            call Leds.greenOn();
        }
    }

    command result_t StdControl.init()
    {
        printfUART_init();
        TOSH_MAKE_VICONSYNC_OUTPUT();

        vsMsgPtr = (ViconSyncMsg*) &(tosSendMsg.data);
        atomic {
            tosSendMsgBusy = FALSE;
        }
        return call Leds.init();        
    }

    command result_t StdControl.start()
    {          
        TOSH_CLR_VICONSYNC_PIN();        
        startPulses();
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        return SUCCESS;
    }


    event result_t Timer_RisingEdge.fired()
    {
        call Leds.redOn();
        edgeCnt++;
        vsMsgPtr->edgeCnt = edgeCnt;

        vsMsgPtr->localTime = call GlobalTime.getLocalTime(); 
        vsMsgPtr->isSynched = (uint16_t) call GlobalTime.getGlobalTime(&(vsMsgPtr->globalTime));
        TOSH_SET_VICONSYNC_PIN();
        if (edgeCnt == 1)
            call Timer_FallingEdge.start(TIMER_ONE_SHOT, 2L*TIMER_FALLINGEDGE_INTERVAL);
        else
            call Timer_FallingEdge.start(TIMER_ONE_SHOT, TIMER_FALLINGEDGE_INTERVAL);
                                  
        if (vsMsgPtr->isSynched)
            call Leds.yellowOn();
        else
            call Leds.yellowOff();


        // (3) - Send the message
        atomic {
            if (!tosSendMsgBusy) {
                if (call SendMsg.send(TOS_UART_ADDR, sizeof(ViconSyncMsg), &tosSendMsg) == FAIL) {
                    atomic tosSendMsgBusy = FALSE;
                    printfUART("ViconSyncM:sendStatusMsg() - ERROR! Can't place msg on send buffer! msgAddr= 0x%x\n", &tosSendMsg);
                }
                else
                    tosSendMsgBusy = TRUE;
            }
        }                     
                      
        return SUCCESS;
    }

    event result_t Timer_FallingEdge.fired()
    {
        TOSH_CLR_VICONSYNC_PIN();
        call Leds.redOff();
        return SUCCESS;
    }

    event result_t SendMsg.sendDone(TOS_MsgPtr msgPtr, result_t sendResult)
    {
        atomic tosSendMsgBusy = FALSE;
        if (sendResult == SUCCESS) { // message sent succesfully
        }
        else {
            printfUART("ViconSyncM:SendMsg.sendDone() - ERROR! msg TX FAILED, msgAddr= 0x%x\n", msgPtr);
        }

        return sendResult;
    }

    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr tosMsgPtr)
    {
        ViconSyncCmdMsg *cmdMsgPtr = (ViconSyncCmdMsg*) tosMsgPtr->data;

        if (cmdMsgPtr->cmdID == 0)
            stopPulses();
        else if (cmdMsgPtr->cmdID == 1)
            startPulses();
        else // invalid cmdID
            assertUART(0);     

        return tosMsgPtr;
    }
}
