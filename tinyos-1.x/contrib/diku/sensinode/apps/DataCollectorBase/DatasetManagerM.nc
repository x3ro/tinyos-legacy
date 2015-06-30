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


module DatasetManagerM {
	provides {
		interface DatasetManager;
	}
	uses {
		interface UARTFrame;
	}
}

implementation {

	intervals_t * currentList;
	
	uint8_t send[128];
    bool isSending = FALSE, sendingFrame = FALSE, repostSendTask = FALSE;
    
    task void sendFrameTask();

	/**************************************************************************
	** 
	**************************************************************************/
	command void DatasetManager.clear()
	{

	}
		
	/**************************************************************************
	** 
	**************************************************************************/

	command void DatasetManager.insertFragment(dataset_t * set, fragment_t * part)
	{
		uint16_t i;

		if (isSending)
			return;
			
		isSending = TRUE;

		/* set */
		send[2] = set->source >> 8;
		send[3] = set->source;
		send[4] = set->number >> 24;		
		send[5] = set->number >> 16;		
		send[6] = set->number >> 8;		
		send[7] = set->number;		
		send[8] = set->size >> 8;		
		send[9] = set->size;		

		/* fragment */
		send[10] = part->pageNumber >> 8;		
		send[11] = part->pageNumber;		
		send[12] = part->fragment;		
		send[13] = part->total;		
		send[14] = part->start;		
		send[15] = part->length;		

		for (i = 0; i < part->length; i++) 
		{
			send[i + 16] = part->pagePtr[i];
		}

		/* header */
        send[0] = part->length + 1 + 8 + 6 + 2;
		send[1] = UART_FRAME_FRAGMENT;

        post sendFrameTask();
	}
        
	/**************************************************************************
	** 
	**************************************************************************/
	command void DatasetManager.checkDataset(dataset_t * set, intervals_t * list, uint8_t * statistics)
	{
		uint8_t i;
		
		if (isSending)
			return;
			
		isSending = TRUE;

		currentList = list;

		/* set */
		send[2] = set->source >> 8;
		send[3] = set->source;
		send[4] = set->number >> 24;		
		send[5] = set->number >> 16;		
		send[6] = set->number >> 8;		
		send[7] = set->number;		
		send[8] = set->size >> 8;		
		send[9] = set->size;		

		/* fragment */
		send[10] = statistics[0];		

		for (i = 0; i < statistics[0]; i++)
		{
			send[i + 11] = statistics[i + 1];
		}

		/* header */
		send[0] = statistics[0] + 1 + 8 + 2;
		send[1] = UART_FRAME_INIT;

        post sendFrameTask();
	}

    task void sendFrameTask()
    {
        result_t res;

        res = call UARTFrame.sendFrame(send);
        
        if (res == SUCCESS)
            sendingFrame = TRUE;
        else
            repostSendTask = TRUE;
    }

	/**************************************************************************
	** UARTFrame
	**************************************************************************/
	event void UARTFrame.sendFrameDone(uint8_t * frame)
	{
        if (repostSendTask)
        {
            post sendFrameTask();
            repostSendTask = FALSE;
        }
        else if (sendingFrame)
        {
            sendingFrame = FALSE;
    		isSending = FALSE;
        }
	}

	event void UARTFrame.receivedFrame(uint8_t * frame)
	{
		uint8_t i;
		
		if (frame[0] > 0) 
		{
			switch(frame[1]) {
				case UART_FRAME_RETRANSMIT:
					/* retransmission requested */
					if (!isSending)
					{
						isSending = TRUE;
						call UARTFrame.sendFrame(send);
					}
					break;
					
				case UART_FRAME_INIT:
					currentList->length = (frame[2] > currentList->max) ? currentList->max : frame[2];
			
					/* missing pages from dataset */
					for (i = 0; i < currentList->length; i++)
					{
						currentList->intervalPtr[i] = frame[4*i+3];
						currentList->intervalPtr[i] = (currentList->intervalPtr[i] << 8) + frame[4*i+4];
						currentList->intervalPtr[i] = (currentList->intervalPtr[i] << 8) + frame[4*i+5];
						currentList->intervalPtr[i] = (currentList->intervalPtr[i] << 8) + frame[4*i+6];
					}

					signal DatasetManager.checkDatasetDone();
					break;
					
				default:
					break;
			}
		}
		
	}

	
}
