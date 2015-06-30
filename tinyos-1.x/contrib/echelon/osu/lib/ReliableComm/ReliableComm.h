/**
 * Copyright (c) 2004 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#ifndef RELIABLE_COMM_H
#define RELIABLE_COMM_H 1 

#define SEND_QUEUE_SIZE	25            //should be no more than 127
#define MAX_NUM_CHILDREN  5
#define NUM_BASE_ACK_BUFFERS 8  //this implies that (SEND_QUEUE_SIZE - NUM_BASE_ACK_BUFFERS 
                                                                         //are used for UART communication at the base station

//#define TOSSIM_SYSTIME 1 //to be removed in deployment; only for debugging in TOSSIM
//#define INTEGRITY_CHECKING 1 //to be removed in deployment; only for checking the integrity of the multi-tier queuing

//for tossim
//#define DBG_SWITCH DBG_USR1
//#define DBG_SWITCH2 DBG_USR2
//#define DBG_SWITCH3 DBG_USR3

//#define EXPLICIT_ACK 1 //to use explicit ack
#define USE_MacControl 1 //to use interface MacControl 
//#define LOG_STATE 1 //to be uncommented if write log state into flash
//#define CALCULATE_LOG 1 //whether to calculate logging information
//#define REPORT_LOG_WHILE_ALIVE 1

#define L1 10 //congestion control
#define L2 4
#define INIT_PARENT_SPACE (SEND_QUEUE_SIZE>>1)
#define STABILIZE_PARENT_SPACE 2
#define PARENT_TO_SEND_DEV 2
//#define CONTENTION_TOTAL_WEITGHT_part 11 //actual total weight is exp(2, deFactoMaxTransmitCount+CONTENTION_TOTAL_WEITGHT_sub)
#define channelUtilizationGuard 3  //about 1.17% probability not hearing packets in channel 
//#define consrvFactor 2 //??? to be randomized
#define compConsrvFactor 1 //<<compConsrvFactor
//#define pastW 7/8
#define compPastW 3 //>>compPastW: should be less than or equal to 5
//#define devPastW 3/4
#define compDevPastW 2 //>>compDevPastW: 
//#define DEV_WEIGHT 4
#define compDevWeight 1 //<<compDevWeight
#define MTTE 180   //millisecond
#define MTTS 90   //millisecond
#define MTTE_DEV 64
#define MTTS_DEV 32
#define MIN_MTTE 46 //millisecond (or 46)
#define MAX_MTTE_THRESHOLD 1200
#define MIN_MTTS 24 //millisecond (or 23)
#define MAX_MTTS_THRESHOLD 600

/* For LiTes
//#define JIFFIES_PER_MILLISECOND  32
#define compJIFFIES_PER_MILLISECOND 5 //exp(2, 5)
*/
//For echelon: mtts, mtte, etc, are in terms of milliseconds
#define compJIFFIES_PER_MILLISECOND 0 //each unit is a millisecond
//#define SYSTIME_UNITS_PER_MILLISECOND 921.6
#define compSYSTIME_UNITS_PER_MILLISECOND 10 //approx. expt(2, 10)

#define HANDLER_ID_LOWER_BOUND    80
#define HANDLER_ID_UPPER_BOUND   90
#define firstMaxTransmitCount 3
#define MAX_TRANSMIT_COUNT   3 //no more than (32-CONTENTION_TOTAL_WEITGHT_part-1)

//#define BASE_STATION_ID  0  //echelon
#define BASE_ACK_DEST_ID 0xfffe
#define UART_HANDLER_ID 91

#define Timer_Interval                 128                   //milliseconds

#define NULL8 0xff
#define NULL16 0xffff
#define NULL32 0xffffffff

typedef struct {
  uint16_t myAddr;
  uint8_t myPos;
  uint8_t mySeq;
#ifndef EXPLICIT_ACK
  uint8_t np0; //next "sent" queue postion
  uint8_t np1; //next "to be queued" position

  uint16_t frAddr; //the last forwarder/sender of the packet
  uint8_t frPos;
  uint8_t frSeq;

  uint8_t cumulLeft; //for block ack
  uint8_t cumulRight; 
#endif

  uint8_t emptyElements; //# of empty queue positions
  uint8_t cvq; //the highest ranked virtual queue having at least one packet
  uint8_t cvqSize; //size the VQ[cvq]
  uint16_t mtte; //mean time to empty a queue position
  uint16_t mtts; //mean time to send out a packet to air
} ReliableComm_ProtocolMsg; 
//Note: the size of ReliableComm_Control is 19 bytes; in LiTes, routing payload was 10-14 bytes; thus, need to modify TOSH_DATA_LENGTH (defined in AM.h) to 28-32. 

#ifndef EXPLICIT_ACK
#define aggregatedACK 5
#define baseAckWait 2
typedef struct {
  uint16_t frAddr; 
  uint8_t frPos;
  uint8_t frSeq;
  uint8_t cumulLeft; 
  uint8_t cumulRight; 
} Base_Ack_Msg;  //for aggregated ack from base stations
#endif

//for self-stabilization
#define MAX_BASE_ACK_DEAD_COUNT  3 //# of times
#define NonBasePendingDeadThreshold  1000 //millisecond

//for tuning parameters
#define DefaultTransmissionPower 255
#define ReliableComm_Tuning_Handler 150 
#define ReliableComm_Tuning_Addr 286 
typedef struct {
  uint8_t transmissionPower; 
  uint8_t maxTransmitCount;
} ReliableComm_Tuning_Msg; 

//for state logging
#define ReliableComm_Log_Handler 160
#define ReliableComm_Log_Addr 296
#define Min_Log_Interval 30000  //milliseconds
#define MAX_NUM_PARENTS  3
#define LOG_LENGTH 3
#define MAX_WRITING_LOG_DEAD_COUNT 10
#define FIRST_LOG_SECTION 32
#define SECOND_LOG_SECTION 30
#define LOG_RECORD_SIZE 62
typedef struct {
  uint8_t type1; //1: marker1

  //routing structure
  uint8_t myID;
  //uint8_t myParentID;

  //queuing condition
  uint8_t queueLength;
  uint16_t queueOverflowCount;
  uint16_t otherQueueOverflowCount;

  //sending 
  uint16_t totalSendsCalled;  //for ReliableSendMsg.send(...)
  uint16_t totalPacketsSent; 
  uint16_t twiceTried;  //at least tried twice 
  uint16_t tripleTried;  //at least three times
  uint16_t delayedACK; 
  //uint16_t maxRetransmitFailureCount;  //???
  //uint16_t otherMaxRetransmitFailureCount; //???
  struct link_sending {
    uint8_t node_id;
    uint16_t totalSendsCalled;
    uint16_t totalPacketsSent;
  } linkSending[MAX_NUM_PARENTS];

  uint8_t type2; //2: marker2

  //receiving
  uint16_t totalPacketsReceived;
  uint16_t receivedDuplicates;
  struct link_reception {
    uint8_t node_id;
    uint16_t totalPacketsReceived;
    uint16_t receivedDuplicates;
  } linkReception[MAX_NUM_CHILDREN];

  /*
  uint8_t transmissionPower; 
  uint8_t maxRetrasmitCount; 
  uint16_t baseRetransmitWaiting;
  uint16_t randomWaitingRange; 
  uint16_t additiveFlowControlWaiting;
  */
} ReliableComm_Reflector; 

#endif
