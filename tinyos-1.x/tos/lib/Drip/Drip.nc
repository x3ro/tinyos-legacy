//$Id: Drip.nc,v 1.1 2005/10/27 21:29:43 gtolle Exp $

/*									tab:4
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

includes Drip;

/**
 * The Drip interface is used to initialize a Drip channel and send
 * messages into it.
 *
 * @author Gilman Tolle <get@cs.berkeley.edu>
 *
 */

interface Drip {
  
  /** 
   * You must call this in StdControl.init(). It sets up local state. 
   */
  command result_t init();

  /**
   * If you have saved a copy of the sequence number to persistent
   * storage, call this in StdControl.init() after retrieving your
   * copy.
   */
  command result_t setSeqno(uint16_t seqno);

  /** 
   * This event is signalled when the Trickle algorithm must rebroadcast
   * the value. Fill in the given buffer pointer, then call rebroadcast. 
   */
  event result_t rebroadcastRequest(TOS_MsgPtr msg, void *pData);

  /**
   * Call this from rebroadcastRequest() once you have filled the
   * buffer pointer.
   */
  command result_t rebroadcast(TOS_MsgPtr msg, void *pData, uint8_t len);

  /** 
   * Call this when you have changed the value locally, and would like
   * to disseminate new data with an incremented sequence number.
   * Once this is called, you will be receiving a rebroadcastRequest
   * event shortly.
   */
  command result_t change();
}
