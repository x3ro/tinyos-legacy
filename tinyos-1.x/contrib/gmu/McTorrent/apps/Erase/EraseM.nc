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

includes Erase;

module EraseM {
    provides {
        interface StdControl;
    }
    uses {
        interface StdControl as SubControl;
        interface Mount;
        interface BlockWrite;
        interface Leds;
        interface FlashWP;
        interface Timer;
    }
}

implementation {
    
    command result_t StdControl.init() {
        call SubControl.init();
        return SUCCESS;
    } 

    command result_t StdControl.start() {
        call SubControl.start();
        call Leds.init();
        call Timer.start(TIMER_ONE_SHOT, 1024);
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call SubControl.stop();
        return SUCCESS;
    }

    event result_t Timer.fired() {
        call FlashWP.clrWP();
        return SUCCESS;
    }

    event void FlashWP.clrWPDone() {
        call Mount.mount(BLOCKSTORAGE_VOLUME_ID);
    }

    event void Mount.mountDone(storage_result_t result, volume_id_t id) {
        if (result == STORAGE_OK) {
            call BlockWrite.erase();
        }
        return;
    }

    event void BlockWrite.eraseDone(storage_result_t result) {
        if (result == STORAGE_OK) {
            call BlockWrite.commit();
        }
        return;
    }

    event void BlockWrite.writeDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) {}

    event void BlockWrite.commitDone(storage_result_t result) {
        if (result == STORAGE_OK) call Leds.greenOn();
        return;
    }

    event void FlashWP.setWPDone() { }
}
