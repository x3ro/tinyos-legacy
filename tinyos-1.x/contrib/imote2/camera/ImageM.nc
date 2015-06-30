/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**                                         
 * Description - Image module.
 *
 * @author Konrad Lorincz
 * @version 1.0, July 11, 2005
 */
includes pxa27x_registers;
includes HWTest;
includes KAC9648;
includes RegUtils;
includes Image;
includes ImageMsg;
includes PrintfUART;

module ImageM 
{
    provides interface StdControl;
    provides interface Image;
    
    uses interface Timer;
    uses interface Leds;
    uses interface SendMsg;
}
implementation 
{
    // =========================== Data =============================
    TOS_Msg sendMsg;
    ImageMsg *imageMsgPtr;
 
    bool pendingFragSend = FALSE;
    uint32_t nextDataStartIndex = 0;


    // =========================== Methods ==========================
    task void sendNextFrag();


    /**
     * Used for Debugging - turns on the leds corresponding to the parameter and exits the program
     * @param errValue, the value to display on the leds (in binary)
     */
    void errorToLeds(uint8_t errValue)
    {
        atomic {
            if (errValue & 1) call Leds.redOn();
            else call Leds.redOff();
            if (errValue & 2) call Leds.greenOn();
            else call Leds.greenOff();
            if (errValue & 4) call Leds.yellowOn();
            else call Leds.yellowOff();

            exit(1);
        }
    }




    command result_t StdControl.init() 
    {
        printfUART_init();
        call Leds.init();
        atomic imageMsgPtr = (ImageMsg*) sendMsg.data;

        return SUCCESS;
    }



    command result_t StdControl.start() 
    {
        return SUCCESS;
    }

    command result_t StdControl.stop() 
    {
        return call Timer.stop();
    }

    
    // --------------------------- For Transfering the Image -------------------------
    void scheduleNextSend()                    
    {
        if (call Timer.start(TIMER_ONE_SHOT, 5) == FAIL) {
            // serious error
            printfUART("ImageM.scheduleNextSend() - ERROR, exiting!!!\n", "");
            errorToLeds(7);
        }
    }



    command result_t Image.send()
    {
        if (!pendingFragSend) {
            atomic nextDataStartIndex = 0;
            scheduleNextSend();
            return SUCCESS;
        }
        else
            return FAIL;        
    }

    /** Called when the timer expires. */
    event result_t Timer.fired()
    {
        if (post sendNextFrag() == FAIL) {
            signal Image.sendDone(FAIL);
            return FAIL;
        }               
        return SUCCESS;
    }

    void setByteArray32Bit(uint8_t data[], uint32_t value)
    {
        int i = 0;

    }

    /**
     * Construct and send a new beacon message.  The transmission power will cycle
     * through <code>freqChans</code> and <code>txPower</code>
     */
    task void sendNextFrag()
    {
        if (!pendingFragSend) {

            memcpy(&imageMsgPtr->startIndex[0], &nextDataStartIndex, 4);
            if (ImageMsg_DATA_SIZE < Image_DATA_SIZE - nextDataStartIndex)
                imageMsgPtr->dataSize = ImageMsg_DATA_SIZE;
            else
                imageMsgPtr->dataSize = Image_DATA_SIZE - nextDataStartIndex;

            memcpy(&imageMsgPtr->data[0], &image.data[nextDataStartIndex], imageMsgPtr->dataSize * 4); 


            atomic pendingFragSend = TRUE;
            if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(ImageMsg), &sendMsg)) {
                atomic pendingFragSend = FALSE;
                // Can't send message
                scheduleNextSend();
                return;
            } 
        } 
        else {
            // Can't send message - still sending previous!?
            scheduleNextSend();
            return;
        }
    }

    /**
     * Indicates whether the beacon message was sent succesfully.
     */
    event result_t SendMsg.sendDone(TOS_MsgPtr msgPtr, result_t sendResult)
    {
        if (sendResult == SUCCESS) {
            // Successfully transmited msg
            atomic nextDataStartIndex += ImageMsg_DATA_SIZE;
        }
        else {            
            // Failed to transmit msg                     
        }

        atomic pendingFragSend = FALSE;
        
        // If there is more stuff to send, schedule a send
        if ( nextDataStartIndex < Image_DATA_SIZE )
            scheduleNextSend();
        else
            signal Image.sendDone(SUCCESS);

        return sendResult;
    }        

}


