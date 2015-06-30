// $Id: sensorboard.h,v 1.2 2006/12/01 00:13:03 binetude Exp $

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
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

TOSH_ALIAS_OUTPUT_ONLY_PIN(ACCEL_LOW_CLK, PW0);
TOSH_ALIAS_OUTPUT_ONLY_PIN(ACCEL_LOW_CS, PW1);
TOSH_ALIAS_OUTPUT_ONLY_PIN(ACCEL_HIGH_CLK, PW2);
TOSH_ALIAS_OUTPUT_ONLY_PIN(ACCEL_HIGH_CS, PW3);

TOSH_ALIAS_OUTPUT_ONLY_PIN(TEMP_CS, PW4);
TOSH_ALIAS_OUTPUT_ONLY_PIN(TEMP_SCK, PW6);


TOSH_ALIAS_PIN(ACCEL_LOW_VERTICAL, INT0);
TOSH_ALIAS_PIN(ACCEL_LOW_HORIZONTAL, INT1);
TOSH_ALIAS_PIN(ACCEL_HIGH_HORIZONTAL, INT2);
TOSH_ALIAS_PIN(ACCEL_HIGH_VERTICAL, INT3);

TOSH_ALIAS_PIN(TEMP_SIO, PW5);

