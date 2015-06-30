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

#ifdef PLATFORM_PC
includes global;
#endif
includes McTorrent;
includes BlockStorage;

module DataManagementM {
    provides {
        interface DataManagement;
    }
    uses {
        interface FlashWP;
        interface Mount;
        interface BlockRead;
        interface BlockWrite;
        interface Crc;

        interface Leds;
    }
}

implementation {
    
#include "BitVecUtils.h"

    enum {
       S_INIT = 0,
       S_MOUNT = 1,
       S_READ_METADATA,
       S_WRITE_METADATA,
       S_READ_PKT,
       S_WRITE_PKT,
       S_ERASE,
       S_IDLE,
    };

    typedef struct {
       uint8_t pageId;
       uint8_t pktId;
       uint8_t  data[BYTES_PER_PKT];
    } RxPktQEntry;

    enum {
       RX_PKTQ_SIZE = 10,
    };

    ObjMetadata _metadata;
    RxPktQEntry _rxPktQ[RX_PKTQ_SIZE];
    uint8_t     _rxPktQHead = 0;
    uint8_t     _rxPktQTail = 0;
    uint8_t     _state;

#define RX_PKTQ_EMPTY (_rxPktQHead == _rxPktQTail)
#define RX_PKTQ_FULL (((_rxPktQTail + 1) % RX_PKTQ_SIZE) == _rxPktQHead)
#define RX_PKTQ_ADV(ptr) ((ptr) = (((ptr) + 1) % RX_PKTQ_SIZE))
#define RX_PKTQ_CLR { _rxPktQHead = 0; _rxPktQTail = 0; }

    static inline uint16_t getPktOffset(uint8_t pageId, uint8_t pktId) {
        return (pageId * BYTES_PER_PAGE + pktId * BYTES_PER_PKT
                + METADATA_SIZE
               );
    }
    
#ifdef PLATFORM_PC
    static inline void simLoadMetadata() {
        if (__isBase()) {
            int i;
            // Base has the complete image.
            _metadata.objId = 1;
            _metadata.numPages = TOTAL_PAGES;
            _metadata.numPktsLastPage = PKTS_PER_PAGE;
            _metadata.numPagesComplete = TOTAL_PAGES;
            for (i = 0; i < TOTAL_PAGES; i++) __receivePage(i);
            __finish();
        } else {
            _metadata.objId = 0;
        }
    }
#endif

    command result_t DataManagement.init() { 
#ifdef PLATFORM_PC
        simLoadMetadata();
        signal DataManagement.initDone(SUCCESS);
        return SUCCESS;
#else 
        // Clear flash's write-protection in case it was set.
        return call FlashWP.clrWP();
#endif
    }

    event void FlashWP.clrWPDone() {
        _state = S_MOUNT;
        call Mount.mount(BLOCKSTORAGE_VOLUME_ID_0);
    }

    event void FlashWP.setWPDone() {}

    event void Mount.mountDone(storage_result_t result, volume_id_t id) {
        // Read the metadata.
        _state = S_READ_METADATA;
        call BlockRead.read(0, &_metadata, METADATA_SIZE);
    }


    event void BlockRead.readDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) {
        switch (_state) {
            case S_READ_METADATA:
                if (result != STORAGE_OK) {
                    signal DataManagement.initDone(FAIL);
                } else {
                    uint16_t crc;
                    crc = call Crc.crc16(&_metadata, 
                        offsetof(ObjMetadata, crcMeta));
                    if (crc != _metadata.crcMeta) {
                        // Metadata corrupted, reset objId.
                        _metadata.objId = 0;
                    }   
                    signal DataManagement.initDone(SUCCESS);
                }
                _state = S_IDLE;
                break;

            case S_READ_PKT:
                signal DataManagement.readPktDone(SUCCESS);
                _state = S_IDLE;
                break;
            default:
                break;
        }
    }


    command uint16_t DataManagement.getObjId() { 
        return _metadata.objId;
    }

    command uint16_t DataManagement.getCrcData() {
        return _metadata.crcData;
    } 

    command uint8_t DataManagement.getNumPages() {
        return _metadata.numPages; 
    }

    command uint8_t DataManagement.getNumPktsLastPage() {
        return _metadata.numPktsLastPage;
    }

    command uint8_t DataManagement.getNextPageId() { 
        return _metadata.numPagesComplete; 
    }

    command result_t DataManagement.updateObj(uint16_t objId, 
        uint8_t numPages, uint8_t numPktsLastPage,
        uint16_t crcData) {

        dbg(DBG_USR1, "Updating object from %d to %d (%d pages, %d packets in last page, CRC=%d)\n", _metadata.objId, objId, numPages, numPktsLastPage, crcData);

        _metadata.objId = objId;
        _metadata.numPages = numPages;
        _metadata.numPktsLastPage = numPktsLastPage;
        _metadata.numPagesComplete = 0;
        _metadata.crcData = crcData;
#ifdef PLATFORM_PC
        return SUCCESS;
#else
        RX_PKTQ_CLR;
        _state = S_ERASE;
        call BlockWrite.erase();
        return SUCCESS;
#endif
    }

    task void writePktTask() {
        RxPktQEntry * entry = &_rxPktQ[_rxPktQHead];
        _state = S_WRITE_PKT;
        call BlockWrite.write(getPktOffset(entry->pageId, entry->pktId),
            entry->data, BYTES_PER_PKT);
    }

    event void BlockWrite.eraseDone(storage_result_t result) {
        call BlockWrite.commit();
    }

    event void BlockWrite.writeDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) {
        switch (_state) {
            case S_WRITE_PKT:
                if (result == STORAGE_OK) {
                    RX_PKTQ_ADV(_rxPktQHead);
                } 
                if (!RX_PKTQ_EMPTY) { 
                    post writePktTask(); 
                } else {
                    _state = S_IDLE;
                    if (_metadata.numPagesComplete == _metadata.numPages) {
                        // All data packets received and written.
                        // Now save the metadata.
                        _metadata.pad = 0;
                        _metadata.crcMeta = call Crc.crc16(&_metadata,
                            offsetof(ObjMetadata, crcMeta));
                        _state = S_WRITE_METADATA;
                        call BlockWrite.write(0, &_metadata, METADATA_SIZE);
                    }
                }
                break;
            case S_WRITE_METADATA:
                call BlockWrite.commit();
                break;
            default:
                break;
        }
    }

    command result_t DataManagement.writePkt(uint8_t pageId, uint8_t pktId, uint8_t * data) {
#ifdef PLATFORM_PC
        return SUCCESS;
#else
        RxPktQEntry * entry = NULL;
        atomic {
            if (!RX_PKTQ_FULL) {
                entry = &_rxPktQ[_rxPktQTail];
                RX_PKTQ_ADV(_rxPktQTail);
            } 
        }
        if (entry == NULL) {
            return FAIL;
        } else {
            entry->pageId = pageId;
            entry->pktId = pktId;
            memcpy(entry->data, data, BYTES_PER_PKT);
            if (_state == S_IDLE) post writePktTask();
            return SUCCESS;
        }
#endif
    }

    command result_t DataManagement.readPkt(uint8_t pageId, uint8_t pktId, uint8_t * data) {

#ifdef PLATFORM_PC
        signal DataManagement.readPktDone(SUCCESS);
        return SUCCESS;
#else
        _state = S_READ_PKT;
        call BlockRead.read(getPktOffset(pageId, pktId), data, BYTES_PER_PKT);
        return SUCCESS;
#endif
    }

    command result_t DataManagement.flushPage() {
#ifdef PLATFORM_PC
        __receivePage(_metadata.numPagesComplete);
#endif

        _metadata.numPagesComplete++;

#ifdef PLATFORM_PC
        if (_metadata.numPagesComplete == _metadata.numPages)
            __finish();
#endif 
        return SUCCESS;
    }

    event void BlockWrite.commitDone(storage_result_t result) { 
        switch (_state) {
            case S_ERASE:
                if (!RX_PKTQ_EMPTY) {
                    // Already receiving new packets.
                    post writePktTask();
                } else {
                    _state = S_IDLE;
                }
                break;
            case S_WRITE_METADATA:
                _state = S_IDLE;
                signal DataManagement.newObjComplete();
                break;
            default: 
                break; 
        }
        return;
    } 

    event void BlockRead.computeCrcDone(storage_result_t result, uint16_t crc, block_addr_t addr, block_addr_t len) {
    }

    event void BlockRead.verifyDone(storage_result_t result) { 
    } 

    command result_t DataManagement.setPageBitVec(uint8_t * bitvec) {
        int i;
        memset(bitvec, 0, PAGE_BITVEC_SIZE);
        if (_metadata.numPagesComplete == (_metadata.numPages - 1)) {
            for (i = 0; i < _metadata.numPktsLastPage; i++)
                BITVEC_SET(bitvec, i);
        } else {
            for (i = 0; i < PKTS_PER_PAGE; i++)
                BITVEC_SET(bitvec, i);
        }
        return SUCCESS;
    }


}


