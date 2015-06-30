/**
 * Copyright (c) 2008 - George Mason University
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

module MsgBufM {
    provides interface MsgBuf;
}

implementation {
    enum {
        NUM_MSG_BUFS = 4
    };

    TOS_Msg msgBuf[NUM_MSG_BUFS];
    uint8_t used = 0;

    command TOS_MsgPtr MsgBuf.getMsgBuf() {
        uint8_t i;
        for (i = 0; i < NUM_MSG_BUFS; i++) {
            if ((used & (1 << i)) == 0) {
                used |= (1 << i);
                return &(msgBuf[i]);
            }
        }
        return NULL;
    }

    command void MsgBuf.putMsgBuf(TOS_MsgPtr msg) {
        uint8_t i;
        for (i = 0; i < NUM_MSG_BUFS; i++) {
            if (&(msgBuf[i]) == msg) {
                used &= ~(1 << i);
                return;
            }
        }
        return;
    }
}

