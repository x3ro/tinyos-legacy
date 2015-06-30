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
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 * 
 * Physical layer parameters for T-MAC
 *-------------------------------------
 * Based on the parameters from RADIO_CONTROL
 * BANDWIDTH: bandwidth (bit rate) in kbps.
 * ENCODE_RATIO: output/input ratio of the number of bytes of the encoding
 *  scheme. In Manchester encoding, 1-byte input generates 2-byte output.
 * PROC_DELAY: processing delay of each packet in physical and MAC layer, in ms
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */

#ifndef PHY_CONST
#define PHY_CONST

#define BANDWIDTH 80
// 40 == SpiByteFifo's rate in bits/ms
#define ENCODE_RATIO 2
//GPH: should be 1 or 2, but because of the extra delay put in we need something
//like 5
#define PROC_DELAY 5
#define TX_TRANSITION_TIME 0

#endif
