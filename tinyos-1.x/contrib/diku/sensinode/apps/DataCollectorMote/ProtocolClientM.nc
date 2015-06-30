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

includes DatasetManager;

module ProtocolClientM {
	provides {
		interface StdControl;
		interface ProtocolStarter;
	}

	uses {
		interface Connection;
		interface FlashManagerReader;
		interface StatisticsReader;
		interface Statistics as StatNoConnection;
		interface Statistics as StatLostConnection;
		interface Statistics as StatGotConnection;
		interface Timer;	
		interface StdOut;
	}
}

implementation {

#include "config.h"

#define RETRY_CCA					3
#define RETRY_RTT                   5
#define TIME_DELAY_RTT				250
#define NUMBER_OF_INTERVALS			10
#define MAXIMUM_RETRANSMISSIONS     30

/* PACKETS_PER_PAGE * DEFAULT_PAYLOAD > PAGE_SIZE (256) */
//#define PACKETS_PER_PAGE			3
#define PACKET_PAYLOAD				90

	enum packet_types {
		PACKET_TYPE_SET_INIT		= 0x01,
		PACKET_TYPE_PAGE_REQ		= 0x02,
		PACKET_TYPE_SET_COMPLETE	= 0x03,
		PACKET_TYPE_PAGE_FRAGMENT	= 0x04,
		PACKET_TYPE_END				= 0x05,
	};
	
	enum states {
		STATE_OFF 							= 0x00,
		STATE_IDLE							= 0x10,
		STATE_CLIENT_OPEN_CONNECTION		= 0x20,
		STATE_CLIENT_DATASET_BEGIN			= 0x30,
		STATE_CLIENT_DATASET_TRANSMIT		= 0x40,
		STATE_CLIENT_DATASET_END			= 0x50,
		STATE_SERVER						= 0x60,
	};

	void protocol_transmit_set_init(dataset_t * set);
	void protocol_transmit_page_fragment(dataset_t * set, fragment_t * part);
	void protocol_transmit_end(dataset_t * set);

	task void clientPacketHandlerTask();
	task void clientOffloadTask();

	/* variables used in client mode */	
	uint8_t pageBuffer[FLASH_PAGE_SIZE];
	uint8_t * pageBufferPtr;
	uint8_t rttRetry;
    
    uint16_t setInitRetry;

	fragment_t currentPart;
	dataset_t currentSet, oldSet;
	uint8_t currentInterval = 0;

	bool datasetInProgress;

	/* common variables */
	uint8_t currentState;

	intervals_t list;
	uint32_t intervalBuffer[NUMBER_OF_INTERVALS];

	packet_t receivePacket;
	packet_t * receivePacketPtr;

	packet_t protocolPacket;
	packet_t * protocolPacketPtr;

	uint8_t ccaRetry;
		
	/**************************************************************************
	** StdControl
	**************************************************************************/
	command result_t StdControl.init() 
	{
		/* associate pointers with buffers */
		pageBufferPtr = pageBuffer;
		receivePacketPtr = &receivePacket;
		protocolPacketPtr = &protocolPacket;
		
		/* initialize structure to manage missing interval lists */
		list.intervalPtr = intervalBuffer;
		list.length = 0;
		list.max = NUMBER_OF_INTERVALS;
		
		/* initialize structure to keep track of dataset information */
		currentPart.total = (FLASH_PAGE_SIZE % PACKET_PAYLOAD) == 0 ? 
				FLASH_PAGE_SIZE / PACKET_PAYLOAD : FLASH_PAGE_SIZE / PACKET_PAYLOAD + 1;

		datasetInProgress = FALSE;

		/* initialize statistic counters */
		call StatNoConnection.init("NoConn", TRUE);
		call StatLostConnection.init("LstConn", TRUE);
		call StatGotConnection.init("GotConn", TRUE);
	
		return SUCCESS;
	}

	command result_t StdControl.start() 
	{
		uint32_t tmp;
		
		/* setup dataset number as a fusion between startups and counter */
		tmp = call StatisticsReader.getStatisticByName("Startup");
		currentSet.number = tmp << 16;
	
		/* set internal state */
		currentState = STATE_IDLE;
		
		return SUCCESS;
	}
	
	command result_t StdControl.stop() 
	{
		call Connection.reject();

		return SUCCESS;
	}

	/**************************************************************************
	** ProtocolStarter
	**************************************************************************/
	command result_t ProtocolStarter.startOffload()
	{
        uint16_t pages = call FlashManagerReader.getPagesInUse();
        
        /* consistency check */
        if ( (currentState == STATE_IDLE) && (pages > 0) )
        {
    		/* set state */
    		currentState = STATE_CLIENT_OPEN_CONNECTION;

    		/* establish connection */		
    		call Connection.open();

            return SUCCESS;
        }
        else
            return FAIL;

	}

	/**************************************************************************
	** Connection
	**************************************************************************/
	event void Connection.openDone(uint8_t result)
	{
		if (result == SUCCESS)
		{
			call StdOut.print("Connection opened\r\n");

			call StatGotConnection.increment();

			/* progress state */
			currentState = STATE_CLIENT_DATASET_BEGIN;
	
			/* initialize data set */
			if (!datasetInProgress)
			{
				datasetInProgress = TRUE;
				
				currentSet.number++;
				currentSet.size = call FlashManagerReader.getPagesInUse();
			}

			/* transmit dataset begin packet */
			rttRetry = 0;
            setInitRetry = 0;
			protocol_transmit_set_init(&currentSet);

			/* set retransmit timeout */
			call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_RTT);

		}
		else 
		{	
			/* unable to establish connection - retry later */
			currentState = STATE_IDLE;
			signal ProtocolStarter.offloadLater();
			call StatNoConnection.increment();
		}
			
	}

	/**************************************************************************
	** 
	**************************************************************************/
	event packet_t * Connection.receivedPacket(packet_t *packet)
	{
		packet_t * tmp;

		/* switch buffer */
		tmp = receivePacketPtr;
		receivePacketPtr = packet;

		/* post packet handler task */
		post clientPacketHandlerTask();

		return tmp;
	}

	/**************************************************************************
	** 
	**************************************************************************/
	task void clientPacketHandlerTask()
	{
		uint8_t i;
		uint32_t dataset;

		/* data set number */
		dataset = receivePacketPtr->data[0];
		dataset = receivePacketPtr->data[1] + (dataset << 8);
		dataset = receivePacketPtr->data[2] + (dataset << 8);
		dataset = receivePacketPtr->data[3] + (dataset << 8);

		call StdOut.print("CON - dataset no.: ");
		call StdOut.printHexlong(dataset);
		call StdOut.print("\r\n");
				

		switch(currentState)
		{
			case STATE_CLIENT_DATASET_BEGIN: 

				/* consistency check */
				if (dataset != currentSet.number)
				{
					call StdOut.print("CON - Inconsistent dataset number\r\n");
					return;
				}

				if (receivePacketPtr->data_seq_no == PACKET_TYPE_PAGE_REQ)
				{					
					call StdOut.print("CON - Server request page(s)\r\n");

					/* stop retransmission timer */
					call Timer.stop();

                    /* if threshold has been passed - give up for now */
                    if (setInitRetry > MAXIMUM_RETRANSMISSIONS)
                    {
                        call StdOut.print("Retry - give up set init\r\n");

                        /* close connection */
                        call Connection.close();

                        /* regress to former state - retry later */
                        currentState = STATE_IDLE;
                        signal ProtocolStarter.offloadLater();
                        call StatLostConnection.increment();

                        return;
                    }

					/* else progress to next state */
					currentState = STATE_CLIENT_DATASET_TRANSMIT;

					/* number of intervals */
					if (receivePacketPtr->data[4] < list.max)
						list.length = receivePacketPtr->data[4];
					else
						list.length = list.max;

					/* load missing pages list into structure */
					for (i = 0; i < list.length; i++)
					{
						list.intervalPtr[i] = receivePacketPtr->data[4*i+5];
						list.intervalPtr[i] = receivePacketPtr->data[4*i+6] + (list.intervalPtr[i] << 8);
						list.intervalPtr[i] = receivePacketPtr->data[4*i+7] + (list.intervalPtr[i] << 8);
						list.intervalPtr[i] = receivePacketPtr->data[4*i+8] + (list.intervalPtr[i] << 8);

						call StdOut.printHexlong(list.intervalPtr[i]);
						call StdOut.print("\r\n");
					}

					/* process missing pages list */
					post clientOffloadTask();
				
				}
				else if (receivePacketPtr->data_seq_no == PACKET_TYPE_SET_COMPLETE)
				{
					call Timer.stop();

					call StdOut.print("CON - Server has complete set\r\n");
					
					/* progress to next state */
					currentState = STATE_CLIENT_DATASET_END;
					
					/* post end packet */
					oldSet.number = currentSet.number;
					oldSet.size = currentSet.size;
					rttRetry = 0;
					protocol_transmit_end(&oldSet);

					/* set retransmit timeout */
					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_RTT);
				}

				break;

			case STATE_CLIENT_DATASET_END:

				/* consistency check */
				if (dataset != oldSet.number)
				{
					call StdOut.print("CON - Inconsistent dataset number\r\n");
					return;
				}

				if (receivePacketPtr->data_seq_no == PACKET_TYPE_END)
				{
					call Timer.stop();

					call StdOut.print("CON - Close command acknowledge\r\n");

					/* close connection */
					call Connection.close();
					
					/* progress to next state */
					currentState = STATE_IDLE;

                    /* notify about the successfull offload */
                    signal ProtocolStarter.offloadFinished(currentSet.size);

                    /* end current data set */
                    datasetInProgress = FALSE;
				}

				break;
				
			default:
				break;
		}
	}
	
	/**************************************************************************
	** 
	**************************************************************************/
	event void Connection.sendPacketDone(packet_t *packet, result_t result)
	{
		/* check if failure was caused by no CCA */
		if ( (result != SUCCESS) && (++ccaRetry < RETRY_CCA) )
		{
			call StdOut.print("Error - retry: ");
			call StdOut.printHex(ccaRetry);
			call StdOut.print("\r\n");

			/* retransmit packet */
			call Connection.sendPacket(packet);
		} 
		else
		{
			/* process next page fragment */
			if (currentState == STATE_CLIENT_DATASET_TRANSMIT)
			{
				post clientOffloadTask();
			}
		} 
	}

	event void Connection.lost()
	{
		call StdOut.print("CON - connection lost\r\n");
	}


	event void Connection.established()
	{
		call StdOut.print("CON - connection established\r\n");
	}

	/**************************************************************************
	** clientOffloadTask
	**************************************************************************/
	uint16_t endPage, endFragment;

	task void clientOffloadTask()
	{

		/* fragment in process */
		if (currentPart.fragment > 0)
		{
			//call StdOut.print("Transmit: ");
			//call StdOut.printHexword(currentPart.pageNumber);
			//call StdOut.printHexword(currentPart.fragment);
			//call StdOut.print("\r\n");

			/* transmit fragment */
			protocol_transmit_page_fragment(&currentSet, &currentPart);

			/* check if this was the last fragment of the page */
			if ( (currentPart.fragment == endFragment) && (currentPart.pageNumber == endPage) ) {
				currentPart.fragment = 0;
			} else {
				/* update fragment variables */
				currentPart.fragment = (currentPart.fragment + 1) % (currentPart.total + 1);
			
				currentPart.start += currentPart.length;
				currentPart.pagePtr += (currentPart.length * sizeof(uint8_t));

				if ( (currentPart.start + currentPart.length) > FLASH_PAGE_SIZE)
					currentPart.length = FLASH_PAGE_SIZE - currentPart.start;
			}
						
			return;
		}
		
		/* no more pages in list */
		if (currentInterval == list.length)
		{
			call StdOut.print("End of list\r\n");
			/* reset state variables */
			currentInterval = 0;

			/* get new list from server */

			/* change state */
			currentState = STATE_CLIENT_DATASET_BEGIN;

			/* transmit dataset begin packet */
			rttRetry = 0;
			protocol_transmit_set_init(&currentSet);

			/* set retransmit timeout */
			call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_RTT);
			
			return;
		}
		
		//call StdOut.print("Get page from interval\r\n");

		/* find next fragment and page in interval */
		currentPart.pageNumber = (list.intervalPtr[currentInterval] & 0x0FFF0000) >> 16;
		currentPart.fragment = ((list.intervalPtr[currentInterval] & 0xF0000000) >> 28) + 1;
		
		/* find last fragment and page in interval */
		endPage = list.intervalPtr[currentInterval] & 0x00000FFF;
		endFragment = ((list.intervalPtr[currentInterval] & 0x0000F000) >> 12) + 1;

		/* update interval index */
		if (currentPart.pageNumber == endPage)
			currentInterval++;
		else {
			list.intervalPtr[currentInterval] &= 0x0FFFFFFF;
			list.intervalPtr[currentInterval] += 0x00010000;
		}

		/* setup fragment to be transmitted */
		currentPart.start = (currentPart.fragment - 1) * PACKET_PAYLOAD;
		currentPart.length = ( (currentPart.start + PACKET_PAYLOAD) > FLASH_PAGE_SIZE) ?
								 (FLASH_PAGE_SIZE - currentPart.start) : PACKET_PAYLOAD;
		currentPart.pagePtr = &pageBufferPtr[currentPart.start];

		/* consistency check - does page and fragment fit */
		if ( (currentPart.pageNumber > (currentSet.size - 1)) 
			|| (currentPart.fragment > currentPart.total) ) {
			/* panic */
			currentInterval = list.length;
			currentPart.fragment = 0;

			post clientOffloadTask();
		}

		/* get page from flash */		
		call FlashManagerReader.getPage(currentPart.pageNumber, pageBufferPtr);
	}

	/**************************************************************************
	** FlashManagerReader
	**************************************************************************/
	event void FlashManagerReader.pageReady(uint16_t page_no)
	{
/*		uint16_t i;

		for (i = 0; i < FLASH_PAGE_SIZE; i++)
		{
			pageBufferPtr[i] = i;	
		}		
		
		pageBufferPtr[0] = page_no >> 8;
		pageBufferPtr[1] = page_no;

		call StdOut.print("Page: ");
		call StdOut.printHexword(page_no);
		call StdOut.print("\r\n");

		for (i = 0; i < FLASH_PAGE_SIZE; i++)
		{
			call StdOut.printHex(pageBufferPtr[i]);	
		}		
		call StdOut.print("\r\n");
*/
		/* keep record of current page in buffer */
		//currentPage = page_no;
		
		
		post clientOffloadTask();
	}

		
	

	/**************************************************************************
	** Timer
	**************************************************************************/
	event result_t Timer.fired()
	{

		switch(currentState)
		{
			case STATE_OFF:
				break;

			/******************************************************************
			** client related code
			******************************************************************/
			case STATE_CLIENT_OPEN_CONNECTION:
			
				call StdOut.print("TIMER - retry connection open\r\n");

				/* retry establish connection */		
				call Connection.open();

				break;
			case STATE_CLIENT_DATASET_BEGIN: 

                if (++rttRetry < RETRY_RTT)
				{
					call StdOut.print("TIMER - retry dataset identifier\r\n");

					/* transmit dataset begin packet */
					protocol_transmit_set_init(&currentSet);

					/* set retransmit timeout */
					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_RTT);
				}
				else
				{
					call StdOut.print("TIMER - give up set init\r\n");

					/* close connection */
					call Connection.close();

					/* regress to former state - retry later */
					currentState = STATE_IDLE;
					signal ProtocolStarter.offloadLater();
					call StatLostConnection.increment();

				}

				break;

			case STATE_CLIENT_DATASET_TRANSMIT:

				call StdOut.print("TIMER - transmit data\r\n");

				break;
			case STATE_CLIENT_DATASET_END:

                if (++rttRetry < RETRY_RTT)
				{
					call StdOut.print("TIMER - retry end\r\n");

					/* retransmit dataset end packet */
					protocol_transmit_end(&oldSet);

					/* set retransmit timeout */
					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_RTT);
				}
				else
				{
					call StdOut.print("TIMER - give up end\r\n");

					/* close connection */
					call Connection.close();

					/* progress to next state */
					currentState = STATE_IDLE;

                    /* notify about the successfull offload */
                    signal ProtocolStarter.offloadFinished(currentSet.size);

                    /* end current data set */
                    datasetInProgress = FALSE;
				}

				break;
				
			default:
				call StdOut.print("Error - unknown state\r\n");
				break;
		}
			
		
		return SUCCESS;
	}

	/**************************************************************************
	** Helper functions
	**************************************************************************/

	/* transmit dataset identifier */
	void protocol_transmit_set_init(dataset_t * set)
	{
		uint8_t size;
		ccaRetry = 0;
        setInitRetry++;

        /* get total size of statistics */
        /* size is stat[1]...stat[110] - with stat[0] holding size */
        size = call StatisticsReader.getStatisticsBufferSize();
        size = (size > 110) ? 110 : size;
        
		/* header information */
		protocolPacketPtr->length = 16 + size; // 7 + 7 + size + 2;
		protocolPacketPtr->data_seq_no = PACKET_TYPE_SET_INIT;

		/* data set number */
		protocolPacketPtr->data[0] = set->number >> 24;
		protocolPacketPtr->data[1] = set->number >> 16;
		protocolPacketPtr->data[2] = set->number >> 8;
		protocolPacketPtr->data[3] = set->number;

		/* number of pages in data set */
		protocolPacketPtr->data[4] = set->size >> 8;
		protocolPacketPtr->data[5] = set->size;

		/* mote statistics size */ 
// hack - need to remove +1 and reprogramme basestation
		protocolPacketPtr->data[6] = size + 1;

        /* update statistics */
        call StatisticsReader.getStatistics( &(protocolPacketPtr->data[7]), size);
					
		call Connection.sendPacket(protocolPacketPtr);
	}

	/* transmit page fragment */
	void protocol_transmit_page_fragment(dataset_t * set, fragment_t * part)
	{
		uint8_t i;
		
		/* header information */
		protocolPacketPtr->length = 19 + part->length; // 7 + 10 + length + 2;
		protocolPacketPtr->data_seq_no = PACKET_TYPE_PAGE_FRAGMENT;

		/* data set number */
		protocolPacketPtr->data[0] = set->number >> 24;
		protocolPacketPtr->data[1] = set->number >> 16;
		protocolPacketPtr->data[2] = set->number >> 8;
		protocolPacketPtr->data[3] = set->number;

		/* page number */
		protocolPacketPtr->data[4] = part->pageNumber >> 8;
		protocolPacketPtr->data[5] = part->pageNumber;

		/* fragment no */
		protocolPacketPtr->data[6] = part->fragment;
		protocolPacketPtr->data[7] = part->total;

		/* interval */
		protocolPacketPtr->data[8] = part->start;
		protocolPacketPtr->data[9] = part->length;

		//call StdOut.print(" - length: ");
		//call StdOut.printHex(part->length);
		//call StdOut.print(" - ");

	
		/* page fragment */
		for (i = 0; i < part->length; i++)
		{
			protocolPacketPtr->data[i+10] = part->pagePtr[i];
		}
		
		ccaRetry = 0;

		call Connection.sendPacket(protocolPacketPtr);		
	}

	/* transmit control packet ending session */
	void protocol_transmit_end(dataset_t * set)
	{
		/* header information */
		protocolPacketPtr->length = 13; // 7 + 4 + 2;
		protocolPacketPtr->data_seq_no = PACKET_TYPE_END;

		/* data set number */
		protocolPacketPtr->data[0] = set->number >> 24;
		protocolPacketPtr->data[1] = set->number >> 16;
		protocolPacketPtr->data[2] = set->number >> 8;
		protocolPacketPtr->data[3] = set->number;
			
		ccaRetry = 0;

		call Connection.sendPacket(protocolPacketPtr);
	}
		

	/**************************************************************************
	** StdOut
	**************************************************************************/
	uint8_t key;

	task void keyHandle();
	
	async event result_t StdOut.get(uint8_t data)
	{
		atomic key = data;
		
		post keyHandle();
		
		return SUCCESS;
	}

	task void keyHandle()
	{
		uint8_t buffer[2];
		
		atomic buffer[0] = key;
		
		switch(buffer[0])
		{

			case '\r':
				call StdOut.print("\r\n");
				break;
				
			default:
				buffer[1] = '\0';

				call StdOut.print(buffer);
		}
	}
}
