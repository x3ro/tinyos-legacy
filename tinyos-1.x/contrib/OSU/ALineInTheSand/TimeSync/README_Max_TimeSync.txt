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
 * Author: Vineet Mittal (mittalv@cis.ohio-state.edu)
 *
 */

TIMESYNC MAX
------------

Each node maintains two variables: Clock and Vclock. Clock is a cache of the CPU counter and represents the local time at the clock which is never reset or adjusted.  Vclock is the global time which the node learns from its neighboring nodes. Initially, Vclock = Clock for every node when it is first started. 

Every node periodically (once in 15 seconds -- can be changed) broadcasts the variables Clock and Vclock to its neighboring nodes. Upon receiving the beacon, the node compares its Vclock with that received in the beacon. If Beacon[Vclock] > Vclock then the node sets Vclock = Beacon[Vclock] otherwise the beacon is discarded. Thus, the node with the maximum value of Vclock is the leader (which may change dynamically if some node has faster clock, or nodes join/leave, or when the network is partitioned. There can also be multiple leaders in the network.) 

The above implementation gives accuracy within 150 jiffies per hop. We also have a more accurate version of timesync which uses the follwoing optimizations:

To get around the variable MAC delay before packet transmission, the message is timestamped just before it is ready to be sent, i.e. when the random delay has expired and the channel has been sensed as idle. Furthermore, to get around the random delay when the packet is received, the comparison between the clock values (i.e., Vclock and Beacon[Vclock]) is done even before the message receive signal is invoked. For this the radio stack (file CC1000RadioIntM.c) has been modified (important when integrating other services).

This implementation gives accuracy within 10 jiffies per hop. The experiments show that most of the time the accuracy is within 3-4 jiffies but due to some non-determinism it can go upto 10 jiffies or so. Further experiments are under way to remove this non-determinism and to also account for clock skew.

The optimized code been checked in to the CVS server under the folder /nest/TimeSyncMax.

