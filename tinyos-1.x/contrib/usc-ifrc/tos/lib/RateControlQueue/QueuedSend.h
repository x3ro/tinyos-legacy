/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */

#ifndef QUEUED_H
#define QUEUED_H

enum { 
    
#ifndef ALPHA
    ALPHA = 2, 
#endif
    
#ifdef IFRC_QUEUE_SIZE
    MESSAGE_QUEUE_SIZE = IFRC_QUEUE_SIZE,
#else 
    MESSAGE_QUEUE_SIZE = 64,
#endif 

#ifdef IFRC_MAX_TRANSMIT
    MAX_RETRANSMIT_COUNT = IFRC_MAX_TRANSMIT,
#else
    MAX_RETRANSMIT_COUNT = 5,
#endif
    
};

enum {
    DEFAULT_CONG_BACKOFF = 3*0x3F,
    DEFAULT_INIT_BACKOFF = 3*0xF,    
    BS_CONG_BACKOFF      = 0x3F/2,
    BS_INIT_BACKOFF      = 0xF/2,    
};

#endif 
