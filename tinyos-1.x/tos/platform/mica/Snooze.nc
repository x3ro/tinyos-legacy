// $Id: Snooze.nc,v 1.3 2003/10/07 21:46:29 idgay Exp $

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
 *
 * Authors:		Joe Polastre
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check http://webs.cs.berkeley.edu/tos/hardware/diode_html.html
 * That page also has information for how to install the diode.
 *
 * $Id: Snooze.nc,v 1.3 2003/10/07 21:46:29 idgay Exp $
 */

/**
 * Snooze interface for putting a mote to sleep for a given period of time.
 * @author Joe Polastre
 **/
interface Snooze
{
  /**
   * Triggers the mote to put itself in a low power sleep state for
   * a specified amount of time.
   * 
   * @param length Length of the low power sleep in units of 1/32 of a second.
   *
   * @return SUCCESS if the mote is about to enter the sleep state
   **/
  async command result_t snooze(uint16_t length);

  /**
   * Event fired when a mote wakes up out of the low power sleep state.
   *
   * @return Always return <code>SUCCESS</code>.
   **/
  async event result_t wakeup();
}
