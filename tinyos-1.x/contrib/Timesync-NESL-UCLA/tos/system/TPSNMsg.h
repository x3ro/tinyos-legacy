/**********************************************************************
Copyright ©2003 The Regents of the University of California (Regents).
All Rights Reserved.

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose, without fee, and without written 
agreement is hereby granted, provided that the above copyright notice 
and the following three paragraphs appear in all copies and derivatives 
of this software.

IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE 
PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF 
CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, 
ENHANCEMENTS, OR MODIFICATIONS.

This software was created by Ram Kumar {ram@ee.ucla.edu}, 
Saurabh Ganeriwal {saurabh@ee.ucla.edu} at the 
Networked & Embedded Systems Laboratory (http://nesl.ee.ucla.edu), 
University of California, Los Angeles. Any publications based on the 
use of this software or its derivatives must clearly acknowledge such 
use in the text of the publication.
**********************************************************************/
/*********************************************************************
 Description: A Header file defining the parameters than can tune
 the TPSN algorithm.
 *****************************************************************/


#ifndef TSMsg_H_
#define TSMsg_H_

#include "../interfaces/SClock.h"

/**
 * Defines the time in MTicks after which a node sends a request
 * for a level if it has not received a level by that time.
 **/
#define LEVEL_DISCOVERY_TIMEOUT 5


/**
 * Defines the time in MTicks after which a node timesout waiting
 * for acknowledgement of TimeSync message and re-transmits the
 * message.
 **/
#define TS_ACK_TIMEOUT 3


/**
 * Maximum number of Ack misses that a node tolerates before 
 * declaring its parent dead and sending a new level discovery
 * message.
 **/
#define ACK_MISS_TOLERANCE 4


/**
 * Structure of the TimeSynchronization Message
 **/
typedef struct TSMsg {
  uint16_t src;
  GTime timestamp1;
} TSMsg;


/**
 * Structure of the TimeSynchronization Acknowledgement Message
 **/
typedef struct TSACKMsg {
  uint16_t src;
  GTime timestamp1;
  GTime timestamp2;
  GTime timestamp3;
} TSACKMsg;


/**
 * Structure of the Level Discovery Message 
 **/
typedef struct LDSMsg {
  uint16_t src;
  uint8_t level;
} LDSMsg;


/** 
 * Structure of the Level Request Message
 **/
typedef struct LREQMsg {
  uint16_t src;
} LREQMsg;


/**
 * Note: AM 4,5,6 and 7 are being used by the protocol and therefore do not use
 * these AMs in your application.
 **/
enum {
  AM_TSMSG = 4,
  AM_TSACKMSG = 5,
  AM_LDSMSG = 6,
  AM_LREQMSG = 7
};

enum {
  ONE_SHOT = 0,
  PERIODIC = 1,
  TIMER_STOP = 2
};

#endif
