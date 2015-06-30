/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
//scale in millisecs
#define REL_MAIN_TIMER  (40L)





//Default  parameters  and packet values
// version number of the protocol
#define REL_VER_NUM                  (1)   
 // size of the fragment. is this correct?? 
//#define REL_FRAG_SIZE                (15)  

#define REL_FRAG_PERIOD              (100L)  // in millisecs. minimum 
                                            //period between fragments


#define REL_WIN_SIZE                 (16L)    // the window size used for 
                                           // acks-- shoud be multiple of 8



#define REL_ACK_STATUS_ARRAY_SIZE    (REL_WIN_SIZE/8) // note the assumption 
                                                      //for win size above


#define   REL_MAX_ACK_BITMAP_SIZE   (5)  // enough for a window size of 40 
#define   REL_MAX_FRAG_SIZE   (25)   // enough for mote; modify for imote

#define REL_RESEND_CONN_REQ_TIMER     (11)  //scale in 100 millisecs
#define REL_RESEND_CONN_REQ_MAX_TRIES (50)

#define REL_RESEND_ACK_RESEND_TIMER     (13)  //scale in 100 millisecs
#define REL_RESEND_ACK_RESEND_MAX_TRIES (10)



#define REL_MAX_CONN_NUM    (3)// maximum number of connections allowed by the receiver

#define REL_MAX_NET_DELAY        (2*REL_MAIN_TIMER)  // in millisecond scale

// used by first short nack
#define REL_MAX_DATA_STARTUP_TIME (3*REL_MAIN_TIMER) // in milliseconds scale

#define REL_MAX_NACK_TRIES       (5)

#define REL_NMAX_ACKS   (3)

#define REL_STATELESS 1
