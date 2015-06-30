/*  -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Discription --------------------------------------------------------
 * distribute a time stamp to all nodes in the network
 *
 * - Author -------------------------------------------------------------
 * @author Andreas Koepke <koepke@tkn.tu-berlin.de>
 * ========================================================================
 */
includes DTPacket;

module DistributeTSAppM {
    provides {
        interface StdControl;
    }
    uses {
        interface DistributeTS;
        interface Leds;
        interface TDA5250Config;
    }
}
implementation {
    
#define NUM_PACKETS 10

    DT_Packet packets[NUM_PACKETS];
    int index;

    command result_t StdControl.init() { 
        index = 0;
        call Leds.init();
        return SUCCESS;  
    }

    command result_t StdControl.stop()  { 
        return SUCCESS; 
    }

    command result_t StdControl.start() {
        return SUCCESS;
    }

    event void DistributeTS.newTimeStamp(uint16_t originId, uint16_t epoch, const timeval* tv) {
        packets[index].sensortype_data = epoch & 0x0FFF;
        packets[index].tv = *(tv);
        ++index;
        index %= NUM_PACKETS;
        call Leds.yellowToggle();
    }

    task void LowTxTask() {
        if(call TDA5250Config.UseLowTxPower() == FAIL)
            post LowTxTask();
    }
    
    event result_t TDA5250Config.ready() {
        return post LowTxTask();
    }

}
