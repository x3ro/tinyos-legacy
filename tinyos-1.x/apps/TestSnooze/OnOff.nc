// $Id: OnOff.nc,v 1.2 2003/10/07 21:45:22 idgay Exp $

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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * $Id: OnOff.nc,v 1.2 2003/10/07 21:45:22 idgay Exp $
 *
 */



/**
 * Interface to be notified of the node being turned on or off through
 * the radio.  Note that this interface ONLY controls the state of the
 * radio.  HPLPowerManagement should put the mote to sleep if it is idle.
 **/

interface OnOff {

  /**
   * Tell the OnOff interface to turn the mote off
   *
   * @return SUCCESS if the mote can successfully change to an off state
   */
  command result_t off();

  /**
   * A message from the network has requested that the mote turn off
   *
   * @return SUCCESS to turn off, FAIL to keep the mote on
   */
  event result_t requestOff();

  /**
   *  Notification to the application that the mote has been turned on.
   *
   * @return SUCCESS if the mote should stay on, FAIL if the mote should
   *         return to the off state
   **/
  event result_t on();
}










