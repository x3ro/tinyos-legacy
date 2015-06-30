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

includes McTorrent;

module ChannelSelectM {
    provides {
        interface StdControl;
        interface ChannelSelect;
    }
    uses {
        interface Random;
        interface SystemTime;
    }
}

implementation {

    typedef struct {
        uint32_t  timeToFree;  // Estimate of time when the channel should be freed.
    } ChannelInfo;

    ChannelInfo _channelInfo[MC_CHANNELS];


    command result_t StdControl.init() {
        int i;

        for (i = 0; i < MC_CHANNELS; i++) 
            _channelInfo[i].timeToFree = 0;

        return SUCCESS;
    }

    command result_t StdControl.start() {
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        return SUCCESS;
    }

    command result_t ChannelSelect.setChannelTaken(uint8_t channel, uint32_t period) {
        _channelInfo[channel].timeToFree = call SystemTime.getCurrentTimeMillis() + period;
        return SUCCESS;
    }

    command uint8_t ChannelSelect.getFreeChannel() {
#ifdef MC_UNIQUE  // assume each node has a unique data channel

        return ((TOS_LOCAL_ADDRESS % (MC_CHANNELS-1)) + 1);

#elif (MC_CHANNELS==1)  // the single channel case
        uint32_t timeNow = call SystemTime.getCurrentTimeMillis();
        if (_channelInfo[0].timeToFree <= timeNow) return 0;
        else return MC_CHANNELS;

#else  // normal multiple channel cases
        int i;
        uint32_t timeNow = call SystemTime.getCurrentTimeMillis();

        int idx = call Random.rand() % MC_CHANNELS;
        for (i = 0; i < MC_CHANNELS; i++) {
            // In normal multiple channel case, channel 0 is
            // the common channel for control messages, and
            // is never used for data packets.
            if (idx > 0 && _channelInfo[idx].timeToFree <= timeNow)
                return idx;

            idx = (idx + 1) % MC_CHANNELS;
        }
        // All channels are busy.
        // MC_CHANNELS is an invalid channel in any of single or multiple channel cases.
        return MC_CHANNELS;
#endif
    }
}
