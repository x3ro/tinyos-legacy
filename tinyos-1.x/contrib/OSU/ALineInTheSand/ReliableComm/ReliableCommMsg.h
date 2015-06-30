/**
 * Copyright (c) 2003 - The Ohio State University.
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



/* 
 * Authors: Hongwei Zhang, Anish Arora
 */


#ifndef RELIABLE_MSG_HANDLER

//#define RELIABLE_MSG_HANDLER 50
#define HANDLER_ID_LOWER_BOUND    80
#define HANDLER_ID_UPPER_BOUND   90

#define BASE_STATION_ID  0 
#define BASE_ACK_DEST_ID 300

//#define Xstart                            8
#define MyAddrPos                  0 
#define MyQueuePos                2 
#define FromAddrPos               3
#define FromQueuePos             5
#define randomSeq                    6       //for nodes other than base station (in Bask-ack, this field is set to 0xff) 
#define randomSeqAck             7
#define RELIABLE_COMM_LENGTH  11 
/* test
#define MyParent    -5   
#define MyId     -4
#define longestQueueMote        -3
#define longestQueueLen          -1
#define QueueLength                 11
#define TotalSendsCalled              12
#define QueueOverflowCount          13
#define MaxRetransmitFailureCount  14
#define OtherMaxRetranxitFailCount 15
#define RELIABLE_COMM_LENGTH  16
*/

#define SEND_QUEUE_SIZE	32             //should be no more than 128
#define DefaultTransmissionPower 9

#define MAX_RETRANSMIT_COUNT            3
#define Timer_Interval                        55                   //milliseconds
#define BaseRetransmit_Timer           450                 //milliseconds 
#define RandomTimerRange               100                 //milliseconds

#define AdditiveFlowControlTimer   300                 //milliseconds 

#define flowControlDelay                   1200           //for "collective ack" based flow control 
#define flowControlXmitReduction    1

#define MAX_NUM_IMPORTS       12
//#define MAX_NUM_NODES     160

//for self-stabilization
#define MAX_BASE_ACK_DEAD_COUNT  3 
#define NonBaseReliableCommDeadThreshold (MAX_RETRANSMIT_COUNT * (BaseRetransmit_Timer+RandomTimerRange/2) * 2) 

//for tuning parameters
#define ReliableComm_Tuning_Handler 150 
#define ReliableComm_Tuning_Addr 286 
typedef struct {
  uint8_t transmissionPower; 
  uint8_t maxRetrasmitCount; 
  uint16_t baseRetransmitWaiting;
  uint16_t randomWaitingRange; 
  uint16_t additiveFlowControlWaiting;
} ReliableComm_Tuning_Msg; 

#endif
