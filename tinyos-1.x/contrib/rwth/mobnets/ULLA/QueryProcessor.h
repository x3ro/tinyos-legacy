/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

/**
 *
 * Header file for Query Processor
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

  /* bCheckBit - used to bitmask the state */
enum {

  ADDING_QUERY_STATUS = 0x0001,          // reading queries from network
  PARSING_QUERY_STATUS = 0x0002,         // parsing the query
  ROUTING_STATUS = 0x0004,               // routing tuples to queries
	CHECKING_CONDITION_STATUS = 0x0008,    // checking conditions
	SENDING_QUERY_STATUS = 0x0010,         // sending a query message
	PROCESSING_QUERY_STATUS = 0x0020,      // processing a query message
  REMOVING_QUERY_STATUS = 0x0040,        // removing a query

};


