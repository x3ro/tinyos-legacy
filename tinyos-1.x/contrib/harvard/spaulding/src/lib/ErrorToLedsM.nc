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

#include "ErrorToLeds.h"

module ErrorToLedsM 
{
  provides interface StdControl;
  provides interface ErrorToLeds;

  uses interface Leds;
  uses interface SendMsg as SendErrorMsg;
} 
implementation 
{
    TOS_Msg tosSendMsg;
    ErrorToLedsMsg *errorToLedsMsg;
    bool busySending = FALSE;

    command result_t StdControl.init() 
    {
        atomic {
            errorToLedsMsg = (ErrorToLedsMsg *) tosSendMsg.data;
            errorToLedsMsg->sourceAddr = TOS_LOCAL_ADDRESS;
            busySending = FALSE;
        }
        call Leds.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {return SUCCESS;}
    command result_t StdControl.stop()  {return SUCCESS;}

    command void ErrorToLeds.errorToLeds(uint8_t errorLeds, uint16_t errorRadio) 
    {
        atomic { 
            if (errorLeds & 1) call Leds.redOn(); 
            else               call Leds.redOff(); 
            if (errorLeds & 2) call Leds.greenOn(); 
            else               call Leds.greenOff(); 
            if (errorLeds & 4) call Leds.yellowOn(); 
            else               call Leds.yellowOff(); 
        } 
        
        errorToLedsMsg->errorCode = errorRadio;
        atomic {
            if (!busySending) {
                busySending = TRUE;
                if (call SendErrorMsg.send(TOS_BCAST_ADDR, sizeof(ErrorToLedsMsg), &tosSendMsg) == FAIL)
                    busySending = FALSE;                
            }
        }
    } 

    event result_t SendErrorMsg.sendDone(TOS_MsgPtr msg, result_t success) 
    {
        atomic busySending = FALSE;
        //exit(1);  // DO NOT TERMINATE! We are using ErrorToLeds as warnings as well
        return success;
    }
}
