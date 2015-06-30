// $Id: sensorboard.h,v 1.1.1.1 2007/11/05 19:10:39 jpolastre Exp $

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
 * Authors:		Alec Woo, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/* The basic sensor board */

/**
 * @author Alec Woo
 * @author David Gay
 * @author Philip Levis
 */


TOSH_ALIAS_OUTPUT_ONLY_PIN(PHOTO_CTL, PW1); 
TOSH_ALIAS_OUTPUT_ONLY_PIN(TEMP_CTL, PW2);
#if defined (__AVR_ATmega163__)
enum {
  TOSH_ACTUAL_PHOTO_PORT = 1,
  TOSH_ACTUAL_TEMP_PORT = 2,
};
#elif defined (__AVR_AT90S8535__)
enum {
  TOSH_ACTUAL_PHOTO_PORT = 1,
  TOSH_ACTUAL_TEMP_PORT = 2
};
/* no way to get voltage in RENE 1 */
#else
enum {
  TOSH_ACTUAL_PHOTO_PORT = 6,
  TOSH_ACTUAL_TEMP_PORT = 5,
};
#endif

/* These are the end-user values */
enum {
  TOS_ADC_PHOTO_PORT = 1,
  TOS_ADC_TEMP_PORT = 2,
};
