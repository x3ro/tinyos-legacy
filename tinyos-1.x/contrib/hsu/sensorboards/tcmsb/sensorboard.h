// $Id: sensorboard.h,v 1.1 2005/04/13 18:23:30 hjkoerber Exp $

/*								
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
 * Authors:		Alec Woo, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/*
 * @author Alec Woo
 * @author David Gay
 * @author Philip Levis
 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * 
 * $Date: 2005/04/13 18:23:30 $
 * $Revision: 1.1 $
 *
 */

enum {                        // physical ports
  TOSH_ACTUAL_RSSI_PORT =0,   // equals Port A, 0
  TOSH_ACTUAL_TEMP_PORT =1,   // equals Port A, 1
};


enum {
  TOS_ADC_RSSI_PORT = 0,  
  TOS_ADC_TEMP_PORT = 1,      // logical ports
};


TOSH_ALIAS_OUTPUT_ONLY_PIN(TEMP_CTL,EXP_IO_3);
