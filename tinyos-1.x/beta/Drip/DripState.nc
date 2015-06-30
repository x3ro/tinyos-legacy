//$Id: DripState.nc,v 1.4 2005/10/27 02:08:22 kaminw Exp $

/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * DripState is the per-client interface between the Drip component and the
 * DripStateC component, which stores the timing parameters needed for
 * the retransmission algorithm.
 * <p>
 * You do not need to call any functions in this interface, but you
 * must wire DripC to DripStateC once for each channel your component is
 * using, like this:
 * <p>
 * <tt>
 * TestDripM.Drip -> DripC.Drip[AM_TESTDRIPMSG];<br>
 * DripC.DripState[AM_TESTDRIPMSG] -> DripStateC.DripState[unique("DripState")];<br>
 * </tt>
 * <p>
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

interface DripState {

  command result_t init(uint8_t globalKey);
  command uint16_t getSeqno();
  command result_t setSeqno(uint16_t seqno);
  command result_t incrementSeqno();

  command result_t entrySent();
  command bool newMsg(DripMetadata incomingMetadata);
  command result_t fillMetadata(DripMetadata *metadata);
}
