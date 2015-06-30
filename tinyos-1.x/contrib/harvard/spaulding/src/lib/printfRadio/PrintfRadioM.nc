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

#include "PrintfRadioMsgs.h"
#include "PrintfRadio.h"
#include "PrintfUART.h"


module PrintfRadioM
{                                                   
    provides interface StdControl;
    provides interface PrintfRadio;

    uses interface Timer;
    uses interface Leds;                 
    uses interface SendMsg;

    uses interface Queue<PrintfRadioMsg> as Queue;

  #ifdef PRINTFRADIO_DELAYEDSEND_ENABLED
    uses interface Timer as Timer_DelayedSend;            
  #endif

  #if defined(TOSMSG_MACACK_ENABLED)
    uses interface MacControl;
  #endif
} 
implementation
{    
    TOS_Msg tosSendMsg;

    uint16_t cntTimerFired = 0;
    uint16_t printfRadioPrintfNbr = 0;

    enum PrintfRadioState {
        S_IDLE,
        S_READY_TO_SEND,
        S_WAITING_SEND_DONE,
    };      
    enum PrintfRadioState currState;


    // =================== Methods ====================
    void task runCurrState();
    void sendMsg();

    command result_t StdControl.init() 
    {
        NOprintfUART_init();
        call Leds.init(); 
        NOprintfUART("PrintfRadioM: StdControl.init() - called\n");
        atomic {
            printfRadioPrintfNbr = 0;
            currState = S_IDLE;
        }
      #if defined(TOSMSG_MACACK_ENABLED)
        call MacControl.enableAck();
      #endif
        return SUCCESS;
    }

    command result_t StdControl.start() 
    {
        //call Timer.start(TIMER_REPEAT, 2000);
        return SUCCESS;
    }

    command result_t StdControl.stop()  {return SUCCESS;}

    event result_t Timer.fired() 
    {
        cntTimerFired++;
        NOprintfUART("\n\nPrintfRadioM::Timer.fired():  cntTimerFired= %u\n", cntTimerFired);
        call Leds.redToggle();
        return SUCCESS;
    }        

#ifdef PRINTFRADIO_DELAYEDSEND_ENABLED
    event result_t Timer_DelayedSend.fired() 
    {
        sendMsg();
        return SUCCESS;
    }
#endif

    void tryPostReadyToSend()
    {
        if (call Queue.is_empty() == TRUE)
            currState = S_IDLE;
        else if (post runCurrState() == FAIL) {
            while (call Queue.is_empty() == FALSE)
                call Queue.pop();
            currState = S_IDLE;
        }
        else
            currState = S_READY_TO_SEND;
    }

    void sendMsg()
    {
        if (call SendMsg.send(PRINTFRADIO_SEND_ADDR, sizeof(PrintfRadioMsg), &tosSendMsg) == FAIL) {
            NOprintfUART("PrintfRadioM.sendMsg():  SendMsg.send(sendAddr= %u, tosMsgPtr= %p) => FAILED!\n", PRINTFRADIO_SEND_ADDR, &tosSendMsg);
            atomic {tryPostReadyToSend();}
        }
        else {
            NOprintfUART("PrintfRadioM.sendMsg():  SendMsg.send(sendAddr= %u, tosMsgPtr= %p) => success\n", PRINTFRADIO_SEND_ADDR, &tosSendMsg);
            atomic currState = S_WAITING_SEND_DONE;
        }
    }

    void task runCurrState()
    {
        switch(currState) {
            case S_IDLE:
            case S_WAITING_SEND_DONE:
                // Do nothing
                return;

            case S_READY_TO_SEND:
            {
                // (1) - Dequeue the request into the tosSendMsg
                atomic {
                    if (call Queue.is_empty() == TRUE) {
                        currState = S_IDLE;
                        NOprintfUART("PrintfRadioM.runCurrState():  ILLEGAL Queue is empty!\n");
                        assertUART(FAIL);
                        return;
                    }
                    else {
                        *((PrintfRadioMsg*)tosSendMsg.data) = call Queue.pop();
                    }
                }

                // (2) - Try to send the msg
              #ifdef PRINTFRADIO_DELAYEDSEND_ENABLED
                if (call Timer_DelayedSend.start(TIMER_ONE_SHOT, 10) == FAIL) {
                    NOprintfUART("PrintfRadioM.runCurrState():  Timer_DelayedSend.start() => FAILED!\n", PRINTFRADIO_SEND_ADDR, &tosSendMsg);
                    atomic {tryPostReadyToSend();}
                }
              #else
                sendMsg();
              #endif
                return;            
            }  

            default:
                // Do nothing
                return;
        }
    }

    command void PrintfRadio.send(const char *str, uint16_t strSize)
    {  
#ifdef PRINTFRADIO_ENABLED
        // (1) - Make sure we can process the request (i.e. request queue is not full)
        atomic {
            printfRadioPrintfNbr++;
            if (call Queue.is_full() == TRUE)
                return;
            else {
                PrintfRadioMsg prMsg;                            
                prMsg.srcAddr = TOS_LOCAL_ADDRESS;
                prMsg.printfNbr = printfRadioPrintfNbr;

                if (strSize > PRINTFRADIO_DATA_LENGTH) {
                    prMsg.dataSize = PRINTFRADIO_DATA_LENGTH;
                    memcpy(prMsg.data, str, prMsg.dataSize);
                    prMsg.data[prMsg.dataSize-2] = '.';
                    prMsg.data[prMsg.dataSize-1] = '.';
                }
                else {
                    prMsg.dataSize = strSize;
                    memcpy(prMsg.data, str, prMsg.dataSize);
                }

                assertUART(call Queue.push(prMsg) == SUCCESS);
            }

            // Only post task if currState is S_IDLE
            if (currState == S_IDLE)
                tryPostReadyToSend();
        }
#endif
    }

    event result_t SendMsg.sendDone(TOS_MsgPtr tosMsgPtr, result_t result)
    {
        if (result == SUCCESS) {
            NOprintfUART("PrintfRadioM.SendMsg.sendDone(tosMsgPtr= %p, result= success)\n", tosMsgPtr);
        } 
        else {
            NOprintfUART("PrintfRadioM.SendMsg.sendDone(tosMsgPtr= %p, result= FAILED)\n", tosMsgPtr);
        }

        atomic {
            switch(currState) {
                case S_WAITING_SEND_DONE:
                    tryPostReadyToSend();
                    break;

                case S_IDLE:
                case S_READY_TO_SEND:
                default:
                    NOprintfUART("PrintfRadioM::SendMsg.sendDone():  ILLEGAL currState= %u\n", currState);
                    assertUART(FALSE);
                    break;
            }                                               
        }
        
        
        return SUCCESS;
    }
}

