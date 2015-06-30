/**
 * Copyright (c) 2006 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

module McTorrentM {
    provides interface StdControl;
    uses {
        interface StdControl as TimerControl;
        interface StdControl as UARTControl;
        interface StdControl as ChannelStateControl;
        interface StdControl as ChannelSelectControl;
        interface StdControl as ControlPlaneControl;
        interface StdControl as DataPlaneControl;
        interface StdControl as FlashWPControl;
        interface Leds;
    }
}

implementation {

    command result_t StdControl.init() {
        result_t result = SUCCESS;

        result = rcombine(call Leds.init(), result);
        result = rcombine(call TimerControl.init(), result);
        result = rcombine(call UARTControl.init(), result);
        result = rcombine(call ChannelStateControl.init(), result);
        result = rcombine(call ChannelSelectControl.init(), result);
        result = rcombine(call ControlPlaneControl.init(), result);
        result = rcombine(call DataPlaneControl.init(), result);
        result = rcombine(call FlashWPControl.init(), result);
        return result;
    }

    command result_t StdControl.start() {
        result_t result = SUCCESS;

        result = rcombine(call TimerControl.start(), result);
        result = rcombine(call UARTControl.start(), result);
        result = rcombine(call ChannelStateControl.start(), result);
        result = rcombine(call ChannelSelectControl.start(), result);
        result = rcombine(call ControlPlaneControl.start(), result);
        result = rcombine(call DataPlaneControl.start(), result);
        result = rcombine(call FlashWPControl.start(), result);

        return result;
    }

    command result_t StdControl.stop() {
        return SUCCESS;
    }

}



