// $Id: ExternalTempM.nc,v 1.2 2005/10/31 13:26:26 vlahan Exp $

/*                                                                      tab:4
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
 * Authors:             Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */


/*  TEMP_INIT command initializes the device */
/*  TEMP_GET_DATA command initiates acquiring a sensor reading. */
/*  It returns immediately.   */
/*  TEMP_DATA_READY is signaled, providing data, when it becomes */
/*  available. */
/*  Access to the sensor is performed in the background by a separate */
/* TOS task. */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Vlado Handziski (adaptation for the EYES nodes)
 * @author Kevin Klues (adaptation for the EYES nodes)
 */



module ExternalTempM {
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
     TOSH_SET_TEMP_EN_PIN();
     ok1 = call ADCControl.init(); 
     ok2 = call ADCControl.bindPort(TOS_ADC_EXTERNAL_TEMP_PORT, TOSH_ACTUAL_ADC_EXTERNAL_TEMP_PORT);
     return rcombine(ok1, ok2);
  }
  
  command result_t StdControl.stop() {
    TOSH_CLR_TEMP_EN_PIN();
    return SUCCESS;
  }
}

