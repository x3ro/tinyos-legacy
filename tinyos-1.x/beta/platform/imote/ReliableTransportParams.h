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

//#define RELIABLE_TRANSPORT_DEBUG

#define REL_MAIN_TIMER  (40L)

/*
 * Default parameters
 */

#define REL_VER_NUM (1)   // version

/*
 * REL_FRAG_PERIOD : sender throttling delay, 
 * The minimum time (in ms) between two consecutive fragments
 */
#define REL_FRAG_PERIOD (40L) 

/*
 * REL_WIN_SIZE : The size of the ACK window, should be multiple of 8
 */
#define REL_WIN_SIZE  (32L)    

/*
 * REL_ACK_STATUS_ARRAY_SIZE : This assumes that the window size is 
 * a multiple of 8
 */
#define REL_ACK_STATUS_ARRAY_SIZE  (REL_WIN_SIZE/8)

/*
 * BITMAP size is a function of the window size, this assumes a max window
 * size of 40
 */
#define   REL_MAX_ACK_BITMAP_SIZE  (8) 

/*
 * Imote frag size, max of 94, assume DM3 packets for now, and adjust 
 * for header overhead
 */
#define   REL_MAX_FRAG_SIZE  (94) 

/*
 * Scale of these timers in MAIN_TIMER ticks
 */
#define REL_RESEND_CONN_REQ_TIMER     (28) 
#define REL_RESEND_ACK_RESEND_TIMER     (32)

#define REL_RESEND_CONN_REQ_MAX_TRIES (50)
#define REL_RESEND_ACK_RESEND_MAX_TRIES (10)

/*
 * Maximum number of connections allowed by the receiver
 */
#define REL_MAX_CONN_NUM  (1)

/*
 * In ms
 */
#define REL_MAX_NET_DELAY  (50) 

/*
 * Scale in ms, used by first short nack
 */
#define REL_MAX_DATA_STARTUP_TIME (1500) 

#define REL_MAX_NACK_TRIES       (5)

#define REL_NMAX_ACKS   (3)
