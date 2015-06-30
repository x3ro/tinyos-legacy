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
	Author:		Marcus Chang <marcus@diku.dk>
	Klaus S. Madsen <klaussm@diku.dk>
	Last modified:	March, 2007
*/


module ProtocolServerM {
	provides {
		interface StdControl;
	}

	uses {
		interface Connection;
		interface BufferManager;
		interface DatasetManager;
		interface Timer;	
		interface StdOut;
		interface StatisticsReader;
	}
}

implementation {

#include "config.h"

#define RETRY_CCA					3
#define TIME_DELAY_RTT				100
#define NUMBER_OF_INTERVALS			10

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


	void protocol_transmit_page_req(dataset_t * set, intervals_t * list);
	void protocol_transmit_set_complete(dataset_t * set);
	void protocol_transmit_end(dataset_t * set);

	task void serverPacketHandlerTask();

	/* variables used in server mode */
	uint8_t currentState;

	dataset_t currentSet;
	intervals_t list;
	uint32_t intervalBuffer[NUMBER_OF_INTERVALS];

	packet_t receivePacket;
	packet_t * receivePacketPtr;

	packet_t protocolPacket;
	packet_t * protocolPacketPtr;

	uint8_t ccaRetry;

	uint8_t statbuf[128];
		
	/**************************************************************************
	** StdControl
	**************************************************************************/
	command result_t StdControl.init() 
	{
		/* associate pointers with buffers */
		receivePacketPtr = &receivePacket;
		protocolPacketPtr = &protocolPacket;
		
		/* initialize structure to manage missing interval lists */
		list.intervalPtr = intervalBuffer;
		list.length = 0;
		list.max = NUMBER_OF_INTERVALS;
			
		/* reset datamanager */
		call DatasetManager.clear();

		return SUCCESS;
	}

	command result_t StdControl.start() 
	{		
		/* set internal state */
		currentState = STATE_IDLE;

		/* delay acception of connection (radio need to boot up) */
		call Timer.start(TIMER_ONE_SHOT, 1024);
		
		return SUCCESS;
	}
	
	command result_t StdControl.stop() 
	{
		call Connection.reject();

		return SUCCESS;
	}

	/**************************************************************************
	** Connection
	**************************************************************************/
	event void Connection.openDone(uint8_t result)
	{
		;
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
		post serverPacketHandlerTask();

		return tmp;
	}

	/**************************************************************************
	** 
	**************************************************************************/
	task void serverPacketHandlerTask()
	{
		fragment_t part;

		/* client connected */
		currentSet.source = receivePacketPtr->src;
				
		/* dataset in question */
		currentSet.number = receivePacketPtr->data[0];
		currentSet.number = (currentSet.number << 8) + receivePacketPtr->data[1];
		currentSet.number = (currentSet.number << 8) + receivePacketPtr->data[2];
		currentSet.number = (currentSet.number << 8) + receivePacketPtr->data[3];
		
		switch (receivePacketPtr->data_seq_no)
		{
			case PACKET_TYPE_SET_INIT:

				call StdOut.print("CON - Dataset identifier received\r\n");
				
				/* read set size */				
				currentSet.size = receivePacketPtr->data[4];
				currentSet.size = (currentSet.size << 8) + receivePacketPtr->data[5];
				
				/* check dataset for missing pages */
				call DatasetManager.checkDataset(&currentSet, &list, &(receivePacketPtr->data[6]));
			
				break;
				
			case PACKET_TYPE_PAGE_FRAGMENT:
				
				/* read page number */
				part.pageNumber = receivePacketPtr->data[4];
				part.pageNumber = receivePacketPtr->data[5] + (part.pageNumber << 8);

				/* read fragment number */ 
				part.fragment = receivePacketPtr->data[6];
				part.total = receivePacketPtr->data[7];

				/* read interval */
				part.start = receivePacketPtr->data[8];
				part.length = receivePacketPtr->data[9];

				/* set fragment pointer in the middle of the packet */
				part.pagePtr = &(receivePacketPtr->data[10]);

				//call StdOut.print("CON - received: ");
				//call StdOut.printHexword(part.pageNumber);
				//call StdOut.printHexword(part.fragment);
				//call StdOut.print("\r\n");			

				/* insert fragment in dataset */
				call DatasetManager.insertFragment(&currentSet, &part);

				//call StdOut.print("CON - start: ");
				//call StdOut.printHex(part.start);
				//call StdOut.print("\r\n");			
				//call StdOut.print("CON - length: ");
				//call StdOut.printHex(part.length);
				//call StdOut.print("\r\n");			

				//for (i = 0; i < part.length; i++)
				//{
				//	call StdOut.printHex(part.pagePtr[i]);
				//}
				//call StdOut.print("\r\n");			

				
				break;
			
			case PACKET_TYPE_END:

				call StdOut.print("CON - received end connection\r\n");

				/* transmit acknowledge */				
				protocol_transmit_end(&currentSet);
				
				/* close connection */
				call Connection.close();

				break;
				
			default:
				break;
		}
	}

	/**************************************************************************
	** 
	**************************************************************************/
	event void DatasetManager.checkDatasetDone()
	{		
		/* request missing pages or notify about complete set */
		if (list.length > 0)
			protocol_transmit_page_req(&currentSet, &list);
		else
		{
			protocol_transmit_set_complete(&currentSet);
		}

		call StdOut.print("CON - dataset no.: ");
		call StdOut.printHexlong(currentSet.number);
		call StdOut.print("\r\n");
		call StdOut.print("CON - dataset size: ");
		call StdOut.printHexword(currentSet.size);
		call StdOut.print("\r\n");
		call StdOut.print("CON - missing intervals: ");
		call StdOut.printHexword(list.length);
		call StdOut.print("\r\n");

		return;
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
	}

	event void Connection.lost()
	{
		call StdOut.print("CON - connection lost\r\n");
	}


	event void Connection.established()
	{
		call StdOut.print("CON - connection established\r\n");

		/* client initiated connection - set state to server */
		currentState = STATE_SERVER;
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
			** common code
			******************************************************************/
			case STATE_IDLE:

				call StdOut.print("TIMER - delayed init\r\n");

				/* set state */			
				currentState = STATE_SERVER;

				/* listen for connections */		
				call Connection.accept();				
			
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

	/* transmit intervals with page requests*/
	void protocol_transmit_page_req(dataset_t * set, intervals_t * intervalList)
	{
		uint8_t i;
		
		/* header information */
		protocolPacketPtr->length = 14 + 4 * intervalList->length; // 7 + 5 + 4*length + 2;
		protocolPacketPtr->data_seq_no = PACKET_TYPE_PAGE_REQ;

		/* data set number */
		protocolPacketPtr->data[0] = set->number >> 24;
		protocolPacketPtr->data[1] = set->number >> 16;
		protocolPacketPtr->data[2] = set->number >> 8;
		protocolPacketPtr->data[3] = set->number;

		/* number of intervals */
		protocolPacketPtr->data[4] = intervalList->length;
	
		/* missing pages from dataset */
		for (i = 0; i < intervalList->length; i++)
		{
			protocolPacketPtr->data[4*i+5] = intervalList->intervalPtr[i] >> 24;
			protocolPacketPtr->data[4*i+6] = intervalList->intervalPtr[i] >> 16;
			protocolPacketPtr->data[4*i+7] = intervalList->intervalPtr[i] >> 8;
			protocolPacketPtr->data[4*i+8] = intervalList->intervalPtr[i];

			// call StdOut.printHexlong(intervalList->intervalPtr[i]);
			// call StdOut.print("\r\n");
		}
		
		ccaRetry = 0;

		call Connection.sendPacket(protocolPacketPtr);
	}

	/* transmit packet signaling set is complete */
	void protocol_transmit_set_complete(dataset_t * set)
	{
		/* header information */
		protocolPacketPtr->length = 13; // 7 + 4 + 2;
		protocolPacketPtr->data_seq_no = PACKET_TYPE_SET_COMPLETE;

		/* data set number */
		protocolPacketPtr->data[0] = set->number >> 24;
		protocolPacketPtr->data[1] = set->number >> 16;
		protocolPacketPtr->data[2] = set->number >> 8;
		protocolPacketPtr->data[3] = set->number;
			
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
		uint8_t i;
		uint8_t buffer[2];
		
		atomic buffer[0] = key;
		
		switch(buffer[0])
		{
			case '1':
				break;

			case '2':
				call StdOut.print("Accept connections\r\n");
				call Connection.accept();
				break;

			case '3':
				call StdOut.print("Reject connections\r\n");
				call Connection.reject();
				break;

			case '4':
				call StdOut.print("Statistics:\r\n");
				
				statbuf[0] = call StatisticsReader.getStatisticsBufferSize();
				call StatisticsReader.getStatistics(&(statbuf[1]), statbuf[0]);
				
				for (i = 0; i < statbuf[0]; i++)
				{
					call StdOut.printHex(statbuf[i]);
				}
				call StdOut.print("\r\n");
				
				break;

			case '5':
				break;

			case '\r':
				call StdOut.print("\r\n");
				break;
				
			default:
				buffer[1] = '\0';

				call StdOut.print(buffer);
		}
	}
}
