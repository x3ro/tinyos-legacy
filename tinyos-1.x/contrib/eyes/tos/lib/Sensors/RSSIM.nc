
// $Id: RSSIM.nc,v 1.1 2005/01/26 14:13:59 klueska Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/*  OS component abstraction of the analog RSSI sensor and */
/*  associated A/D support.

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Kevin Klues (Adaptation for the Eyes Nodes)
 */


module RSSIM {
  provides interface StdControl;
  uses {
    interface ADCControl;
  }
}
implementation {

  command result_t StdControl.init() {
     return SUCCESS;
  }
  
  command result_t StdControl.start() {
   result_t ok1, ok2;
   ok1 = call ADCControl.init(); 
   ok2 = call ADCControl.bindPort(TOS_ADC_RSSI_PORT, TOSH_ACTUAL_ADC_RSSI_PORT);
   return rcombine(ok1, ok2);
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
}


