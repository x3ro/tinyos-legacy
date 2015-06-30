/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
// Possible actions handled by the power-tracker
enum {
   /*
    * Time in milliseconds, all these fields are 4 bytes long
    * All these counters exclude statistics related times
    * WARNING : If you add enums, update the stats logger with the new
    * sizes
    */
   MSEC_MOTE_ON = 0,		// 0	-
   MSEC_MOTE_TX,		// 1    -
   MSEC_SENSOR_BOARD_ON, 	// 2	-
   MSEC_SENSOR_ANALOG_ON, 	// 3	-
   MSEC_NETWORK_FORMATION,	// 4    -
   MSEC_PER_SENSOR_TRANSFER,	// 5	-
   MSEC_PER_MOTE_TRANSFER,	// 6	-
   MSEC_PER_CLUSTER_TRANSFER,	// 7
   
   // Num packets : All these fields are 2 bytes long
   NUM_RT_SEND_DATA,		// 8	-
   NUM_RT_RECV_DATA,		// 9
   NUM_RT_SEND_NACK,		// 10
   NUM_RT_RECV_NACK, 		// 11	-
   NUM_ROUTING_SEND,		// 12	-
   NUM_ROUTING_RECV,		// 13	-
   NUM_PS_SEND,			// 14	-
   NUM_PS_RECV,			// 15	-
   NUM_DS_SEND,			// 16	-
   NUM_DS_RECV,			// 17	-
   NUM_TOTAL_SEND,		// 18	-
   NUM_TOTAL_RECV,		// 19	-

   // Other : 2 bytes each
   HOP_COUNT_TO_CH,		// 20	-
   ID_OF_NEXT_HOP,		// 21	-

   // Imote specifics
   NUM_NM_SEND,			// 22	-
   NUM_NM_RECV,			// 23	-
   NUM_NP_SEND,			// 24	-
   NUM_NP_RECV,			// 25	-
   NUM_SF_SEND,			// 26	-
   NUM_SF_RECV,			// 27	-
   NUM_NODES_FOUND,	        // 28	-
   
   // END
   NUM_TYPES
};
