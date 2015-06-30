/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye (S-MAC version for mica2), Tom Parker (tnode and T-MAC modifications)
 * 
 * Physical layer parameters for T-MAC
 *-------------------------------------
 * Based on the parameters from RADIO_CONTROL
 * BANDWIDTH: bandwidth (bit rate) in bits/ms
 * ENCODE_RATIO: output/input ratio of the number of bytes of the encoding
 *  scheme. In Manchester encoding, 1-byte input generates 2-byte output, however bandwidth is *after*
 *  manchester, so this should be 1.
 * PROC_DELAY: processing delay of each packet in physical and MAC layer, in ms
 * VALID_RSSI_LIMIT: maximum number of bytes recieved per incoming RSSI value
 * MAX_VALID_RSSI: Highest RSSI value allowed before the byte is considered 
 *   to be background noise
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */

#ifndef PHY_CONST
#define PHY_CONST

#define BANDWIDTH 19
#define ENCODE_RATIO 1
#define PROC_DELAY 5
#define TX_TRANSITION_TIME 3

#if TNODE_SPEED == 8

#if CC1K_DEF_PRESET == 0
#define COUNTER_1_1MS_INTERVAL 8038
#define VALID_RSSI_LIMIT 1
#elif CC1K_DEF_PRESET >= 1 && CC1K_DEF_PRESET <= 5
#define COUNTER_1_1MS_INTERVAL 8020
#define VALID_RSSI_LIMIT 3 
#else
#error Panic! cannot handle this value of CC1K_DEF_PRESET
#endif

#elif TNODE_SPEED == 4
#error COUNTER_1 1ms interval not yet determined for 4mhz tnode!
/*#define COUNTER_1_1MS_INTERVAL 4150*/
#define VALID_RSSI_LIMIT 2

#else
#error Cannot handle that speed of tnode!
#endif

#ifdef FIXED_BATTERY // battery changes mess with ADC values
#define MAX_VALID_RSSI 0x12C
#else
#define MAX_VALID_RSSI 0x100
#endif

#endif

