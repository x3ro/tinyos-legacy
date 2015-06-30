/* Copyright (c) 2007, Marcus Chang, Klaus Madsen
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


module ConnectionM {
	provides {
		interface StdControl;
		interface Connection;
	}
	uses {
		interface StdControl as SimpleMacControl;
		interface SimpleMac;
		interface Timer;
		interface LCG;
		interface LocalTime;
		interface StdOut;		
	}
}

implementation {

#include "cc2420.h"

#define BROADCAST_ADDRESS 						0xFFFF
#define ROLE_NONE								0x00
#define ROLE_CLIENT								0x01
#define ROLE_SERVER								0x02

/* Timeouts based on these defines: */
#define TIME_DELAY_RTT				250
#define TIME_DELAY_CCA				10
#define TIME_DELAY_DT				10
#define TIME_DELAY_RESPONSE_MIN		5  
#define TIME_DELAY_TIMEOUT			5000
#define TIME_DELAY_T1				65
/* t0:	205 ms */ //0x0186
/* t1:   30 ms */ //0x0041
/* t2:   70 ms */ //0x0069
/* t3:  770 ms */ //0x057d
/* t4:  170 ms */ //0x0140
/* t5:  780 ms */ //0x0587


/* Number of retries */
#define RETRY_CCA					3
#define RETRY_PROTOCOL_DISCOVERY	5
#define RETRY_PROTOCOL_ACCEPT		3

	enum states {
		STATE_OFF 							= 0x00,
		STATE_IDLE							= 0x10,
		STATE_CONNECTION_ESTABLISHED		= 0x20,
		STATE_CONNECTION_CLOSING			= 0x30,
		STATE_CLIENT_DISCOVERY_SENT			= 0x40,
		STATE_CLIENT_DISCOVERY_RETRY		= 0x50,
		STATE_CLIENT_OFFER_RECEIVED			= 0x60,
		STATE_CLIENT_OFFER_ACCEPTED			= 0x70,
		STATE_SERVER_DISCOVERY_ACCEPT		= 0x80,
		STATE_SERVER_DISCOVERY_RECEIVED		= 0x90,
		STATE_SERVER_OFFER_SENT				= 0xA0,
	};

	enum packet_types {
		PACKET_TYPE_DISCOVERY 	= 0x0100,
		PACKET_TYPE_OFFER		= 0x0200,
		PACKET_TYPE_ACCEPT		= 0x0300,
		PACKET_TYPE_ACKNOWLEDGE	= 0x0400,
		PACKET_TYPE_DATA 		= 0xFF00,
	};

	/********************/
	/* Server variables */
	/********************/
	uint8_t publicChannel, privateChannel;

	int8_t lastRSSI;
	uint8_t lastSerial;
	uint16_t lastClient;

	/********************/
	/* Client variables */
	/********************/
	int8_t bestServerRSSI, bestClientRSSI;
	uint8_t	bestSerial, bestChannel;
	uint16_t bestServer;
					
	/********************/
	/* Common variables */
	/********************/
	bool activity;
	uint8_t ccaRetry, discoveryRetry, acceptRetry;
	uint16_t connectionAddress;
	
	uint16_t TIME_DELAY_T0, TIME_DELAY_T2, TIME_DELAY_T3, TIME_DELAY_T4, TIME_DELAY_T5;
	
	norace uint8_t currentState, role;

	const mac_addr_t * shortAddress;

	packet_t connectionPacket;
	void connection_transmit_discovery();
	void connection_transmit(uint16_t type, uint16_t receiver, uint8_t serial, uint8_t channel, int8_t rssi);

/*************************************************************************************************
*** StdControl
**************************************************************************************************/

	task void initTask();
	/**********************************************************************
	 * Init
	 *********************************************************************/
	command result_t StdControl.init() 
	{
		call SimpleMacControl.init();

//		publicChannel = CC2420_DEFAULT_CHANNEL;
//		privateChannel = (*shortAddress) % 15 + publicChannel + 1;
//		privateChannel = (privateChannel > 26) ? privateChannel - 16 : privateChannel;

		//publicChannel = 25;
		//privateChannel = 26;

        publicChannel = 26;
        
        switch(TOS_LOCAL_ADDRESS)
        {
            case 0x4B7C:
            case 0x3BF7:
                privateChannel = 11;
                break;
            
            case 0x85F6:
            case 0x82FD:
                privateChannel = 14;
                break;
                
            case 0xA7B2:
            case 0x9645:
                privateChannel = 17;
                break;

            case 0x705B:
            case 0x645B:
                privateChannel = 20;
                break;

            default:
                privateChannel = 23;
                break;
        }
        
		call SimpleMac.setChannel(publicChannel);
//		call SimpleMac.setTransmitPower(CC2420_DEFAULT_POWER);
        call SimpleMac.setTransmitPower(100);
		call SimpleMac.addressFilterEnable();

		call LCG.seed(call LocalTime.read());

		role = ROLE_NONE;
		currentState = STATE_IDLE;

        TIME_DELAY_T4 = TIME_DELAY_RTT + 2 * RETRY_CCA * TIME_DELAY_CCA + TIME_DELAY_DT;

        TIME_DELAY_T2 = TIME_DELAY_T1  + RETRY_CCA * TIME_DELAY_CCA + TIME_DELAY_DT;

        TIME_DELAY_T3 = TIME_DELAY_T2 + RETRY_PROTOCOL_ACCEPT * TIME_DELAY_T4 + 
                        TIME_DELAY_RTT + 3 * RETRY_CCA * TIME_DELAY_CCA + TIME_DELAY_DT;

		TIME_DELAY_T0 = TIME_DELAY_T1 + TIME_DELAY_RESPONSE_MIN + 
                        TIME_DELAY_RTT + 2 * RETRY_CCA * TIME_DELAY_CCA + TIME_DELAY_DT;

		TIME_DELAY_T5 = TIME_DELAY_T3 + TIME_DELAY_DT;
/*
		call StdOut.print("TIME_DELAY_T0:");
		call StdOut.printHexword(TIME_DELAY_T0);
		call StdOut.print("\r\n");
		call StdOut.print("TIME_DELAY_T1:");
		call StdOut.printHexword(TIME_DELAY_T1);
		call StdOut.print("\r\n");
		call StdOut.print("TIME_DELAY_T2:");
		call StdOut.printHexword(TIME_DELAY_T2);
		call StdOut.print("\r\n");
		call StdOut.print("TIME_DELAY_T3:");
		call StdOut.printHexword(TIME_DELAY_T3);
		call StdOut.print("\r\n");
		call StdOut.print("TIME_DELAY_T4:");
		call StdOut.printHexword(TIME_DELAY_T4);
		call StdOut.print("\r\n");
		call StdOut.print("TIME_DELAY_T5:");
		call StdOut.printHexword(TIME_DELAY_T5);
		call StdOut.print("\r\n");
*/
		post initTask();		

		return SUCCESS;
	}

	task void initTask()
	{
		shortAddress = call SimpleMac.getAddress();
	}

	/**********************************************************************
	 * Start/Stop
	 *********************************************************************/
	command result_t StdControl.start()
	{		
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{		
		return SUCCESS;
	}


/*************************************************************************************************
*** Connection related
**************************************************************************************************/

	/**********************************************************************
	 * open
	 *********************************************************************/
	command result_t Connection.open() 
	{
		call SimpleMacControl.start();	
		call SimpleMac.setChannel(publicChannel);

		role = ROLE_CLIENT;
		currentState = STATE_CLIENT_DISCOVERY_SENT;
		discoveryRetry = 0;

		connection_transmit_discovery();
		call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_T0);

		return SUCCESS;
	}

	/**********************************************************************
	 * close
	 *********************************************************************/
	command result_t Connection.close() 
	{
		call Timer.stop();

		/* regress */
		if (role == ROLE_CLIENT)
		{
			call SimpleMacControl.stop();
			role = ROLE_NONE;
			currentState = STATE_IDLE;
		} 
		else
		{
			currentState = STATE_SERVER_DISCOVERY_ACCEPT;
		}

		call SimpleMac.setChannel(publicChannel);

		return SUCCESS;
	}
	
	/**********************************************************************
	 * accept
	 *********************************************************************/
	command result_t Connection.accept() 
	{
		call SimpleMacControl.start();	
		call SimpleMac.setChannel(publicChannel);

		role = ROLE_SERVER;
		currentState = STATE_SERVER_DISCOVERY_ACCEPT;

		return SUCCESS;
	}

	/**********************************************************************
	 * reject
	 *********************************************************************/
	command result_t Connection.reject() 
	{
		call Timer.stop();

		call SimpleMacControl.stop();
		role = ROLE_NONE;
		currentState = STATE_IDLE;

		return SUCCESS;
	}

	/**********************************************************************
	 * sendPacket
	 *********************************************************************/
	
	command result_t Connection.sendPacket(packet_t * packet) 
	{
		if (currentState == STATE_CONNECTION_ESTABLISHED)
		{
			packet->fcf = PACKET_TYPE_DATA;
			packet->dest = connectionAddress;

			return call SimpleMac.sendPacket(packet);
		} else 
		{
			return FAIL;
		}
	
	}

	/**********************************************************************
	 * setPublicChannel
	 *********************************************************************/
	command result_t Connection.setPublicChannel(uint8_t channel) 
	{
		publicChannel = channel;
		privateChannel = (*shortAddress) % 15 + publicChannel + 1;
		privateChannel = (privateChannel > 26) ? privateChannel - 16 : privateChannel;

		call SimpleMac.setChannel(publicChannel);

		return SUCCESS;
	}

	/**********************************************************************
	 * setPrivateChannel
	 *********************************************************************/
	command result_t Connection.setPrivateChannel(uint8_t channel) 
	{
		privateChannel = channel;
		
		return SUCCESS;
	}

	/**********************************************************************
	 * getShortAddress
	 *********************************************************************/
	command uint16_t Connection.getShortAddress() 
	{
		return *shortAddress;
	}

/*************************************************************************************************
*** Timer related
**************************************************************************************************/

	event result_t Timer.fired()
	{

		switch(currentState) 
		{
			case STATE_IDLE:
				call StdOut.print("CON: Error - timer fired in idle state\r\n");
				break;
				
			/******************************************************************
			** Client related
			******************************************************************/
			case STATE_CLIENT_DISCOVERY_SENT:
				call StdOut.print("CON: Timeout: No reply from discovery\r\n");

				call SimpleMacControl.stop();	

				currentState = STATE_CLIENT_DISCOVERY_RETRY;

				call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_T5);
				
				break;

			case STATE_CLIENT_DISCOVERY_RETRY:
				if (++discoveryRetry < RETRY_PROTOCOL_DISCOVERY)
				{
					call SimpleMacControl.start();	

					currentState = STATE_CLIENT_DISCOVERY_SENT;

					connection_transmit_discovery();
					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_T0);
				}
				else
				{
					call StdOut.print("CON: Discovery failed\r\n");

					/* restart */
					call SimpleMacControl.stop();	
					role = ROLE_NONE;
					currentState = STATE_IDLE;
					signal Connection.openDone(STATE_CLIENT_DISCOVERY_SENT);
				}
				break;

			case STATE_CLIENT_OFFER_RECEIVED:
				call StdOut.print("CON: Timeout: Finished waiting for offers\r\n");
				call StdOut.print("CON: Transmitting accept\r\n");

				acceptRetry = 0;
				connection_transmit(PACKET_TYPE_ACCEPT, bestServer, bestSerial + 1, privateChannel, bestServerRSSI);
				call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_T4);

				/* progress */
				currentState = STATE_CLIENT_OFFER_ACCEPTED;

				break;

			case STATE_CLIENT_OFFER_ACCEPTED:
				call StdOut.print("CON: Timeout: No acknowledgement for accept\r\n");

				if (++acceptRetry < RETRY_PROTOCOL_ACCEPT)
				{
					connection_transmit(PACKET_TYPE_ACCEPT, bestServer, bestSerial + 1, privateChannel, bestServerRSSI);
					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_T4);
				}
				else
				{
					/* restart */
					call SimpleMacControl.stop();	
					role = ROLE_NONE;
					currentState = STATE_IDLE;
					signal Connection.openDone(STATE_CLIENT_OFFER_ACCEPTED);
				}

				break;

			/******************************************************************
			** Server related
			******************************************************************/
			case STATE_SERVER_DISCOVERY_RECEIVED:
				call StdOut.print("CON: Timeout: Ready to reply to discovery\r\n");
				call StdOut.print("CON: Transmitting offer\r\n");

				connection_transmit(PACKET_TYPE_OFFER, lastClient, lastSerial + 1, privateChannel, lastRSSI);
				
				call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_T3);

				/* progress */
				currentState = STATE_SERVER_OFFER_SENT;
			
				break;

			case STATE_SERVER_OFFER_SENT:
				call StdOut.print("CON: Timeout: No response to offer\r\n");

				/* regress */
				call StdOut.print("CON: Regress to discovery accept\r\n");
				currentState = STATE_SERVER_DISCOVERY_ACCEPT;
			
				break;

			/******************************************************************
			** Common 
			******************************************************************/
			case STATE_CONNECTION_ESTABLISHED:
				// call StdOut.print("CON: Timeout: Check for inactivity\r\n");

				if (activity) {
					activity = FALSE;
					
					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_TIMEOUT);

				} else {
					call StdOut.print("CON: Connection lost due to inactivity\r\n");

					/* regress */
					if (role == ROLE_CLIENT)
					{
						call SimpleMacControl.stop();
						role = ROLE_NONE;
						currentState = STATE_IDLE;
					} 
					else
					{
						currentState = STATE_SERVER_DISCOVERY_ACCEPT;
					}

					call SimpleMac.setChannel(publicChannel);

					signal Connection.lost();
				}

				break;
			
			default:
				call StdOut.print("CON: Error - unhandled state:");
				call StdOut.printHex(currentState);
				call StdOut.print("\r\n");
				break;
		}

		return SUCCESS;
	}

/*************************************************************************************************
*** MAC related
*************************************************************************************************/

	event packet_t * SimpleMac.receivedPacket(packet_t * packet)
	{
		packet_t * tmp = packet;
		uint8_t randomDelay;
		
		switch(currentState) 
		{
			/******************************************************************
			** Client related
			******************************************************************/
			case STATE_CLIENT_DISCOVERY_SENT:

				if (packet->fcf == PACKET_TYPE_OFFER)
				{
					call Timer.stop();

					/* first offer received best by default */
					bestSerial = packet->data_seq_no; 
					bestServer = packet->src;
					bestClientRSSI = packet->data[0];
					bestChannel = packet->data[1];
					bestServerRSSI = packet->fcs.rssi;

					call StdOut.print("CON: Received offer from: ");
					call StdOut.printHexword(packet->src);
					call StdOut.print(" ");
					call StdOut.printHex(packet->data[0]);
					call StdOut.print(" ");
					call StdOut.printHex(packet->fcs.rssi);
					call StdOut.print("\r\n");

					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_T2);

					/* progress */
					currentState = STATE_CLIENT_OFFER_RECEIVED;
				} else 
				{
					call StdOut.print("CON: Wrong packet type - expected offer\r\n");
				}

				break;
				
			case STATE_CLIENT_OFFER_RECEIVED:

				if (packet->fcf == PACKET_TYPE_OFFER)
				{
					call StdOut.print("CON: Received offer from: ");
					call StdOut.printHexword(packet->src);
					call StdOut.print(" ");
					call StdOut.printHex(packet->data[0]);
					call StdOut.print(" ");
					call StdOut.printHex(packet->fcs.rssi);
					call StdOut.print("\r\n");

					/* check if offer is better than previous */
					if (bestClientRSSI < (int8_t) packet->data[0])
					{
						bestSerial = packet->data_seq_no; 
						bestServer = packet->src;
						bestClientRSSI = packet->data[0];
						bestChannel = packet->data[1];
						bestServerRSSI = packet->fcs.rssi;
					}
				} else 
				{
					call StdOut.print("CON: Wrong packet type - expected offer\r\n");
				}

				break;

			case STATE_CLIENT_OFFER_ACCEPTED:

				if (packet->fcf == PACKET_TYPE_ACKNOWLEDGE)
				{
					call Timer.stop();

					call StdOut.print("CON: Received acknowledge\r\n");

					connectionAddress = bestServer;

					call SimpleMac.setChannel(bestChannel);

					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_TIMEOUT);

					currentState = STATE_CONNECTION_ESTABLISHED;

					signal Connection.openDone(SUCCESS);

				} else 
				{
					call StdOut.print("CON: Wrong packet type - expected accept\r\n");
				}

				break;

			/******************************************************************
			** Server related
			******************************************************************/
			case STATE_SERVER_DISCOVERY_ACCEPT:

				if (packet->fcf == PACKET_TYPE_DISCOVERY)
				{
					call StdOut.print("CON: Discovery packet received\r\n");

					lastSerial = packet->data_seq_no;
					lastClient = packet->src;
					lastRSSI = packet->fcs.rssi;

					randomDelay = TIME_DELAY_RESPONSE_MIN + 5 * (call LCG.next() % 16);

					call StdOut.print("CON: Random: ");
					call StdOut.printHex(randomDelay);
					call StdOut.print("\r\n");

					call Timer.start(TIMER_ONE_SHOT, randomDelay);

					currentState = STATE_SERVER_DISCOVERY_RECEIVED;
				} else 
				{
					call StdOut.print("CON: Wrong packet type - expected discovery\r\n");
				}
				
				break;

			case STATE_SERVER_OFFER_SENT:

				if (packet->fcf == PACKET_TYPE_ACCEPT)
				{
					call Timer.stop();
					call StdOut.print("CON: Accept packet received\r\n");

					lastSerial = packet->data_seq_no;
					lastClient = packet->src;
					lastRSSI = packet->fcs.rssi;
					
					connectionAddress = lastClient;

					connection_transmit(PACKET_TYPE_ACKNOWLEDGE, lastClient, lastSerial + 1, privateChannel, lastRSSI);
					
					call SimpleMac.setChannel(privateChannel);

					call Timer.start(TIMER_ONE_SHOT, TIME_DELAY_TIMEOUT);

					currentState = STATE_CONNECTION_ESTABLISHED;
					signal Connection.established();
				} else 
				{
					call StdOut.print("CON: Wrong packet type - expected accept\r\n");
				}
			
				break;

			/******************************************************************
			** Common
			******************************************************************/
			case STATE_CONNECTION_ESTABLISHED:

				if (packet->fcf == PACKET_TYPE_DATA)
				{
					// call StdOut.print("CON: Received data packet\r\n");

					activity = TRUE;

					tmp = signal Connection.receivedPacket(packet);
				}

				break;
				
			default:
				call StdOut.print("CON: Error - unhandled state:");
				call StdOut.printHex(currentState);
				call StdOut.print("\r\n");
				break;
		}

		return tmp;
	}

	event void SimpleMac.sendPacketDone(packet_t * packet, result_t result)
	{
		
		if (currentState == STATE_CONNECTION_ESTABLISHED)
		{
			activity = TRUE;

			signal Connection.sendPacketDone(packet, result);
		}
		else if (result != SUCCESS)
		{

			if (++ccaRetry < RETRY_CCA)
			{
				call StdOut.print("CON: Error - retry: ");
				call StdOut.printHex(ccaRetry);
				call StdOut.print("\r\n");

				call SimpleMac.sendPacket(&connectionPacket);
			} 
			// else
			// {
			// 	signal Connection.openDone(currentState);		
			// }
		}			
	}
	

/*************************************************************************************************
** Packet utility functions
*************************************************************************************************/
	void connection_transmit_discovery()
	{
		ccaRetry = 0;
		
		connectionPacket.length = 9; // 7 + 0 + 2;
		connectionPacket.fcf = PACKET_TYPE_DISCOVERY;
		connectionPacket.data_seq_no = (call LCG.next() & 0x7F);
		connectionPacket.dest = BROADCAST_ADDRESS;

		// connectionPacket.src = *shortAddress;
		// connectionPacket.fcs.rssi = 0;
		// connectionPacket.fcs.correlation = 0;

		call SimpleMac.sendPacket(&connectionPacket);
	}

	void connection_transmit(uint16_t type, uint16_t receiver, uint8_t serial, uint8_t channel, int8_t rssi)
	{
		ccaRetry = 0;

		connectionPacket.length = 11; // 7 + 2 + 2;
		connectionPacket.fcf = type; 
		connectionPacket.data_seq_no = serial;
		connectionPacket.dest = receiver;
		connectionPacket.data[0] = rssi;
		connectionPacket.data[1] = channel;

		// connectionPacket.src = *shortAddress;
		// connectionPacket.data[2] = distanceToGateway;
		// connectionPacket.data[3] = successRate;
		// connectionPacket.data[4] = batteryStatus;
		// connectionPacket.fcs.rssi = 0;
		// connectionPacket.fcs.correlation = 0;

		call SimpleMac.sendPacket(&connectionPacket);
	}

		
/*************************************************************************************************
** StdOut
*************************************************************************************************/
	
	async event result_t StdOut.get(uint8_t data) {

		return SUCCESS;
	}

}
