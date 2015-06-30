/* Copyright (c) 2006, Marcus Chang, Klaus Madsen
         All rights reserved.

         Redistribution and use in source and binary forms, with or without 
         modification, are permitted provided that the following conditions are met:

         * Redistributions of source code must retain the above copyright notice, 
         this list of conditions and the following disclaimer. 

         * Redistributions in binary form must reproduce the above copyright notice,
         this list of conditions and the following disclaimer in the documentation 
         and/or other materials provided with the distribution. 

         * Neither the name of the Dept. of Computer Science, University of 
         Copenhagen nor the names of its contributors may be used to endorse or 
         promote products derived from this software without specific prior 
         written permission. 

         THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
         AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
         IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
         ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
         LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
         CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
         SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
         INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
         CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
         ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
         POSSIBILITY OF SUCH DAMAGE.
*/      

/*
        Author:         Marcus Chang <marcus@diku.dk>
        Klaus S. Madsen <klaussm@diku.dk>
        Last modified:  March, 2007
*/


module SamplingControllerM {
	provides {
		interface StdControl;
	}

	uses {
        interface Statistics as ControllerStatus;
        interface ThreeAxisAccel as SamplingRaw;
        interface ProtocolStarter;
        interface Timer;
        interface StdOut;
	}
}

implementation {

#include "config.h"

#define TIMER_DELAY 10000

    enum controller_status {
        CONTROLLER_STATUS_NORMAL = 0x00,
        CONTROLLER_STATUS_FAILURE = 0x01,
    };


    uint8_t cache[CONTROLLER_LOOKBACK_SIZE];
    uint16_t idx = 0, errors = 0;
    bool offloadCalled = FALSE;

	command result_t StdControl.init() 
    {
        uint8_t i;
        
        /* initialize look-back cache */
        for (i = 0; i < CONTROLLER_LOOKBACK_SIZE; i++)
        {
            cache[i] = ACCEL_STATUS_SUCCESS;
        }
                
        /* initialize statistic counters */
        call ControllerStatus.init("Status", TRUE);

		return SUCCESS;
	}

	command result_t StdControl.start() 
	{
		return SUCCESS;
	}

	command result_t StdControl.stop() 
	{
		return SUCCESS;
	}

    /**************************************************************************
    ** SamplingRaw
    **************************************************************************/
    event result_t SamplingRaw.dataReady(uint16_t x, uint16_t y, uint16_t z, uint8_t status) 
    {
        /* remove one item from the cache and update the number of errors in cache */
        if (cache[idx] != ACCEL_STATUS_SUCCESS)
            errors -= 1;

        /* insert new item in cachce */
        cache[idx] = status;

        /* update number of errors in cache */            
        if (status != ACCEL_STATUS_SUCCESS)
            errors += 1;
       
        /* update cyclic index */
        if (idx < CONTROLLER_LOOKBACK_SIZE - 1)
            idx += 1;
        else
            idx = 0;

        /* initiate offloading if errorrate is too high */
        if (errors > CONTROLLER_ERROR_THRESHOLD)
        {
            /* once the threshold has been reached, the mote is dead */
            errors = 0xFFFF - CONTROLLER_LOOKBACK_SIZE;
            
            if (!offloadCalled)
            {
                offloadCalled = TRUE;
                call ControllerStatus.set(CONTROLLER_STATUS_FAILURE);

                if (call ProtocolStarter.startOffload() == FAIL)
                    call Timer.start(TIMER_ONE_SHOT, TIMER_DELAY);
            }
                
        }            
        
        return SUCCESS;
    }

    /**************************************************************************
    ** Timer
    **************************************************************************/
    event result_t Timer.fired() 
    {
        if (call ProtocolStarter.startOffload() == FAIL)
            call Timer.start(TIMER_ONE_SHOT, TIMER_DELAY);

        return SUCCESS; 
    }

    /**************************************************************************
    ** ProtocolStarter
    **************************************************************************/ 
    event void ProtocolStarter.offloadLater()
    {   
        offloadCalled = FALSE;
    }
    
    event void ProtocolStarter.offloadFinished(uint16_t acked_pages)
    {
        offloadCalled = FALSE;
    }
	
    /**************************************************************************
    ** StdOut
    **************************************************************************/ 
    async event result_t StdOut.get(uint8_t data)
    {
        return SUCCESS;
    }

}
