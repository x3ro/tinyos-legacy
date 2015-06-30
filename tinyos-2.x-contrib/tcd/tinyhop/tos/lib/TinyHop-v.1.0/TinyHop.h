/*
 * Copyright (c) 2009 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */


/**
 * @author Ricardo Simon Carbajo <carbajor {tcd.ie}>
 * @date   February 13 2009 
 * Computer Science
 * Trinity College Dublin
 */

 
/****************************************************************/
/* TinyHop:														*/
/* An end-to-end on-demand reliable ad hoc routing protocol		*/
/* for Wireless Sensor Networks intended for P2P communication	*/
/*--------------------------------------------------------------*/
/* This version has been tested with TinyOS 2.1.0 and 2.1.1     */
/****************************************************************/


#ifndef _TOS_TINYHOP_H
#define _TOS_TINYHOP_H

#include "AM.h"
#include "message.h"

  //DEFINE TRANSMISSION POWER FOR THE ROUTING PROTOCOL
  #ifndef ROUTING_RFPOWER
  #define ROUTING_RFPOWER CC2420_DEF_RFPOWER
  #endif

  #include <qsort.c>
  void qsort(void *aa, size_t n, size_t es, int (*cmp)(const void *, const void *));

  enum {
	AM_TOS_HOPPINGMSG = 249
  };
 
  enum {
    EMPTY = 0xffff
  };
  
  enum {
	SEND_QUEUE_SIZE = 8,	//20	
	ACK_QUEUE_SIZE = 1,
	ACK_NEW_QUEUE_SIZE = 1
  };

  enum {
	ROUTE_TABLE_SIZE = 25,	//50
	MAX_NUM_MOTES=15,		//50
	MAX_SEQUENCE_MOTE=32535,
	MAX_MEMORY_FILTER=20,
	MAX_PACKETS_ACKED_FILTER=20,
	MAX_ROUTING_FREQ=32535
  };

  enum {
	NEW_ROUTE=0,
	ACK_NEW_ROUTE=1,
	ACK_OF_ACK_NEW_ROUTE=2,
	DISCOVERY_ACK_NEW_ROUTE=3,
	ACK_DISCOVERY_ACK_NEW_ROUTE=4,
	FOLLOW_ROUTE=5,
	ACK_FOLLOW_ROUTE=6,
	BROADCAST = 7
  };

  enum{
	//TIME_RTX_NEW_ROUTE=350,			//That's in Milliseconds
	//TIME_RTX_FOLLOW_ROUTE=150,		//That's in Milliseconds
	//TIME_RTX_ACK_NEW_ROUTE=30			//That's in Milliseconds
     
	//For topologies larger than 32 nodes
	TIME_RTX_NEW_ROUTE=800,				//That's in Milliseconds
	TIME_RTX_FOLLOW_ROUTE=500,			//That's in Milliseconds
	TIME_RTX_ACK_NEW_ROUTE=30		    //That's in Milliseconds
  };
	
  enum{
	MAX_NUM_FOLLOWING_TRIALS=2,		//Maximum number of resending trials if the msg is already following a route 
	MAX_NUM_NEW_ROUTE_TRIALS=2,     //Maximum number of resending trials if the msg it is discovering a route 
	MAX_RE_DISCOVERY_TRIALS=1,	    //Maximum number of retrials if a discovery process for an ack new route has failed
	MAX_TRIALS_ACK_NEW_ROUTE=1		//Maximum number of retrials in sending the ACK_NEW_ROUTE packet, 
									//if an ACK_OF_ACK_NEW ROUTE or a SNOOP packet is not received
  };


/********************************************************************************************************************/
/* Tupla Mote_Address-Sequence																						*/
/********************************************************************************************************************/
typedef struct AddrSeq{
	am_addr_t addr;			
	uint16_t seq;
} AddrSeq;

/********************************************************************************************************************/
/* Routing table which indicate that the packets received for the node "received.addr" with sequence "received.seq" */
/* have to be forwarded to the mote "sent.addr" with sequence "sent.seq". That will form the routes. Each route	    */
/* has a usage frequence value which indicates how frequently this route is being used(reset every certain interval)*/
/********************************************************************************************************************/
typedef struct RoutingTable{
	am_addr_t origin;				//Address of the node that creates the packets that are following this route
	am_addr_t destination;			//Address of the node that finally receives the packets that are following this route
	AddrSeq received;				 
	AddrSeq sent;
	uint16_t usageFreq;					
} RoutingTable;

/********************************************************************************************************************/
/* Reachable Motes (addresses) from the local mote																	*/
/* "targetAddr" = mote address that can be reached from the local mote												*/
/* "sendRoute" = indicates the address and sequence where the msg has to be sent to reach the target mote  		    */
/********************************************************************************************************************/
typedef struct ReachableMotes{
	am_addr_t targetAddr;						
	AddrSeq sendRoute;					
} ReachableMotes;

/********************************************************************************************************************/
/* Memory Filter performs as a LIFO queue to store the most frequent discovery packet routes so to avoid cycles		*/
/* "originAddr" = it indicates who created the packet																*/
/* "seqMsg" = indicate seq for this message																			*/
/********************************************************************************************************************/
typedef struct MemoryFilter{
	am_addr_t originAddr;		
	uint16_t seqMsg;					
} MemoryFilter;

/********************************************************************************************************************/
/* List of Discovery Packets Acked. That allows to control how many NEW_ROUTE packets are acked with a				*/
/*   NEW_ROUTE_ACK packet.																							*/
/* "originAddr" = it indicates who created the packet																*/
/* "seqMsg" = it indicates seq for this message																		*/
/********************************************************************************************************************/
typedef struct PacketsAckedFilter{
	am_addr_t originAddr;		
	uint16_t seqMsg;					
} PacketsAckedFilter;

/********************************************************************************************************************/  
/* Structure of the Message for TinyHop																				*/
/********************************************************************************************************************/
typedef nx_struct TOS_HoppingMsg {
	nx_am_addr_t targetAddr;			//Final destination address for the msg
	nx_am_addr_t originAddr;			//Origin address of the msg
	nx_am_addr_t senderAddr;			//Mote which sends the msg each time (even if it's forwarded)
	nx_uint16_t seqMsg;					//Seq of the message (generated by the origin mote) (automatically reset at max 2^16)
  	nx_uint16_t seqRoute;				//Seq for each packet being sent to perform routing process
	nx_uint8_t type;					//Type of msg being sent: NEW_ROUTE,ACK_NEW_ROUTE,FOLLOW_ROUTE,...
	nx_uint8_t data[0];				
 } TOS_HoppingMsg; 


#endif /* _TOS_TINYHOP_H */
