// $Id: PIRM.nc,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

/*
 * Copyright (c) 2004 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */
includes sensorboard;
module PIRM
{
    provides
    {
        interface StdControl;
    }
    uses
    {
        interface ADCControl;
    }
}
implementation
{
    command result_t StdControl.init()
    {
        call ADCControl.bindPort(TOS_ADC_PIR_A_PORT, TOSH_ACTUAL_PIR_A_PORT);
        TOSH_MAKE_PIR_CTL_OUTPUT();
        TOSH_CLR_PIR_CTL_PIN();
        return call ADCControl.init();
    }

    command result_t StdControl.start()
    {
        TOSH_CLR_PIR_CTL_PIN();
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        TOSH_SET_PIR_CTL_PIN();
        return SUCCESS;
    }
}
