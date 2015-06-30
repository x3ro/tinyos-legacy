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
 *
 * Author: Ted Herman (herman@cs.uiowa.edu)
 *
 */

enum { AM_BEACON=37 };   // please change if needed

  /* In the initial Tsync implementation, one aspect of the
     following structures is not fully implemented:  
     mote id's are only one byte (but coerced to 2 bytes 
     for these structures).  */

// Structure of the Beacon Message
typedef struct beaconMsg 
{
  uint16_t sndId;  // Id of Message Sender
  uint32_t sndVclock; // timestamp of sender
  uint32_t sndClock;  // local Clock of sender
} beaconMsg;	   // 29-byte payload

typedef beaconMsg * beaconMsgPtr;

#define CLOCK_FUZZ 1200 
#define BEACON_ITVL 15


