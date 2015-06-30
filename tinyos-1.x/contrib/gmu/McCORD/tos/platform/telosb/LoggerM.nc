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

/**
 * This module wraps the STM25P block storage read/write access
 * to provide the old LoggerRead/LoggerWrite interfaces (on 16-byte 
 * entries).
 */

includes BlockStorage;
includes Logger;

module LoggerM {
  provides {
    interface LoggerInit;
    interface LoggerRead;
    interface LoggerWrite;
  }
  uses {
    interface Mount;
    interface BlockRead;
    interface BlockWrite;
    interface FlashWP;
  }
}

implementation {
  
  block_addr_t curWriteLine = 0;  // uint32_t
  block_addr_t curReadLine = 0;   // uint32_t
  volume_id_t volumeId;
  bool eraseOnInit;
  bool ready = FALSE;
  

  command result_t LoggerInit.init(volume_id_t volume, bool erase) {
    volumeId = volume;
    eraseOnInit = erase;
    return call FlashWP.clrWP();
  }

  command result_t LoggerWrite.append(uint8_t *data) {
    if (!ready) return FAIL;
    if (call BlockWrite.write(curWriteLine << 4, data, 16) == SUCCESS) {
        curWriteLine++;
        return SUCCESS;
    } else {
        return FAIL;
    }
  }

  command result_t LoggerWrite.write(uint16_t line, uint8_t *data) {
     if (!ready) return FAIL;
     curWriteLine = line;
     if (call BlockWrite.write(curWriteLine << 4, data, 16) == SUCCESS) {
         curWriteLine++;
         return SUCCESS;
     } else {
         return FAIL;
     }
  }

  command result_t LoggerWrite.resetPointer() {
     if (!ready) return FAIL;
     curWriteLine = 0;
     return SUCCESS;
  }

  command result_t LoggerWrite.setPointer(uint16_t line) {
     if (!ready) return FAIL;
     curWriteLine = line;
     return SUCCESS;
  }

  command result_t LoggerRead.readNext(uint8_t *buffer) {
     if (!ready) return FAIL;
     if (call BlockRead.read(curReadLine << 4, buffer, 16) == SUCCESS) {
         curReadLine++;
         return SUCCESS;
     } else {
         return FAIL;
     }
  }

  command result_t LoggerRead.read(uint16_t line, uint8_t *buffer) {
     if (!ready) return FAIL;
     curReadLine = line;
     if (call BlockRead.read(curReadLine << 4, buffer, 16) == SUCCESS) {
         curReadLine++;
         return SUCCESS;
     } else {
         return FAIL;
     }
  }

  command result_t LoggerRead.resetPointer() {
     if (!ready) return FAIL;
     curReadLine = 0;
     return SUCCESS;
  }

  command result_t LoggerRead.setPointer(uint16_t line) {
     if (!ready) return FAIL;
     curReadLine = line;
     return SUCCESS;
  }


  event void FlashWP.clrWPDone() {
    if (call Mount.mount(volumeId) == FAIL)
        signal LoggerInit.initDone(FAIL);
  }

  event void FlashWP.setWPDone() {}


  event void Mount.mountDone(storage_result_t result, volume_id_t id) {
    if (result == STORAGE_OK) {
        if (eraseOnInit == TRUE)
            call BlockWrite.erase();
        else {
            ready = TRUE;
            signal LoggerInit.initDone(SUCCESS);
        }
    }
    else signal LoggerInit.initDone(FAIL);
  }

  event void BlockWrite.writeDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) {
    if (result != STORAGE_OK) signal LoggerWrite.writeDone(FAIL);
    else call BlockWrite.commit();
  }

  event void BlockWrite.eraseDone(storage_result_t result) {
    if (result == STORAGE_OK) {
        if (call BlockWrite.commit() == FAIL)
            signal LoggerInit.initDone(FAIL);
    }
    else signal LoggerInit.initDone(FAIL); 
  }

  event void BlockWrite.commitDone(storage_result_t result) {
    if (result == STORAGE_OK) {
        if (!ready) {
            // commit for erase.
            ready = TRUE;
            signal LoggerInit.initDone(SUCCESS);
        } else {
            // commit for write.
            signal LoggerWrite.writeDone(SUCCESS);
        }
    } else {
        if (!ready) {
            // commit for erase.
            signal LoggerInit.initDone(FAIL);
        } else {
            // commit for write.
            signal LoggerWrite.writeDone(FAIL);
        }
    }
  }

  event void BlockRead.readDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) {
    if (result != STORAGE_OK) signal LoggerRead.readDone(buf, FAIL);
    else signal LoggerRead.readDone(buf, SUCCESS);
  }

  event void BlockRead.computeCrcDone(storage_result_t result, uint16_t crc, block_addr_t addr, block_addr_t len) {
  }

  event void BlockRead.verifyDone(storage_result_t result) {
  }


  default event result_t LoggerWrite.writeDone(result_t success) {
    return SUCCESS;
  }
  default event result_t LoggerRead.readDone(uint8_t *buffer, result_t success) {
    return SUCCESS;
  }
}

