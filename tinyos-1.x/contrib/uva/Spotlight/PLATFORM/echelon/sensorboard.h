// $Id: sensorboard.h,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

/*                                  tab:4
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
 * Authors:     Alec Woo, David Gay, Philip Levis, Prabal Dutta
 * Date last modified:  4/27/04
 *
 */

/**
 * @author Alec Woo
 * @author David Gay
 * @author Philip Levis
 * @author Prabal Dutta
 */


enum
{  
    TOSH_ACTUAL_MIC_PORT = 2, 	
    TOSH_ACTUAL_MAG_X_PORT = 5,
    TOSH_ACTUAL_MAG_Y_PORT = 6,
    TOSH_ACTUAL_PIR_A_PORT = 7,
};

enum
{
    TOS_ADC_MIC_PORT = 2,
    TOS_ADC_MAG_X_PORT = 6,
    TOS_ADC_MAG_Y_PORT = 8,
    TOS_ADC_PIR_A_PORT = 9,
};

enum
{
    TOS_MIC_POT_ADDR = 1,
    TOS_MAG_POT_ADDR = 0,
    TOS_PIR_POT_ADDR = 2,
};

TOSH_ALIAS_OUTPUT_ONLY_PIN(SOUNDER_CTL, PW2);
TOSH_ALIAS_OUTPUT_ONLY_PIN(MAG_CTL, PW5);
TOSH_ALIAS_OUTPUT_ONLY_PIN(PIR_CTL, PW6);

TOSH_ALIAS_OUTPUT_ONLY_PIN(MIC_CTL, PW3);
TOSH_ALIAS_PIN(LPF_CTL, PW7);
TOSH_ALIAS_PIN(LPF_CLK, PWM1A);
TOSH_ALIAS_OUTPUT_ONLY_PIN(MIC_MUX_SEL, PW6);

