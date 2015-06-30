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

includes global;
includes McCORD;
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
    }
}

implementation {
    
#include "BitVecUtils.h"

    enum {
       S_INIT = 0,
       S_MOUNT,
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
    uint8_t *   _allPktsBitVec;

#define RX_PKTQ_EMPTY (_rxPktQHead == _rxPktQTail)
#define RX_PKTQ_FULL (((_rxPktQTail + 1) % RX_PKTQ_SIZE) == _rxPktQHead)
#define RX_PKTQ_ADV(ptr) ((ptr) = (((ptr) + 1) % RX_PKTQ_SIZE))
#define RX_PKTQ_CLR { _rxPktQHead = 0; _rxPktQTail = 0; }

#ifdef HW_DEBUG
    /**
     * The following constants and variables are for debug only.
     */
#define INVALID_PAGE_ID		255
#define INVALID_PKT_ID		255
#define DEBUG_ENTRY_SIZE	16
#define DEBUG_MAX_OFFSET	4080
    uint16_t    _debugOffset = 2048;
#endif

    static inline uint16_t getPktOffset(uint8_t pageId, uint8_t pktId) {
        return (pageId * BYTES_PER_PAGE + pktId * BYTES_PER_PKT
                + METADATA_SIZE
               );
    }

    static inline void initAllPktsBitVec() {
        uint16_t totalPkts;
        uint16_t allPktsBitVecSize;

        totalPkts = (_metadata.numPages - 1) * PKTS_PER_PAGE + _metadata.numPktsLastPage;
        allPktsBitVecSize = (totalPkts - 1)/8 + 1;
        _allPktsBitVec = (uint8_t *)malloc(allPktsBitVecSize);
        memset(_allPktsBitVec, 0, allPktsBitVecSize);
    }

    static inline bool isPktReceived(uint8_t pageId, uint8_t pktId) {
        uint16_t pos = pageId * PKTS_PER_PAGE + pktId;
        return (BITVEC_GET(_allPktsBitVec, pos) == 1);
    }

    static inline void setPktReceived(uint8_t pageId, uint8_t pktId) {
        uint16_t pos = pageId * PKTS_PER_PAGE + pktId;
        BITVEC_SET(_allPktsBitVec, pos);
    }
    
    static inline void checkAndFlushPage(uint8_t pageId) {
        uint16_t pos = pageId * PKTS_PER_PAGE;
        uint16_t endPos;

        if (pageId == _metadata.numPages - 1) {
            // Last page.
            endPos = pos + _metadata.numPktsLastPage;
        } else {
            endPos = pos + PKTS_PER_PAGE;
        }

        for (; pos < endPos; pos++) {
            if (BITVEC_GET(_allPktsBitVec, pos) == 0)
                return; // page not complete 
        }
        
        // We have received a new complete page.

        __receivePage(_metadata.numPagesComplete);

        _metadata.numPagesComplete++;

        return;
    }

#ifdef PLATFORM_PC
    static inline void simLoadMetadata() {
        if (__isBase()) {
            int i;
            // Base has the complete image.
            _metadata.objId = 1;
            _metadata.numPages = TOTAL_PAGES;
            _metadata.numPktsLastPage = PKTS_PER_PAGE;
            _metadata.numPagesComplete = _metadata.numPages;
            for (i = 0; i < _metadata.numPagesComplete; i++) 
                __receivePage(i);
        } else {
            _metadata.objId = 0;
        }
    }
#endif

    static inline void signalInitDone(result_t result) {
#ifdef PLATFORM_PC
        simLoadMetadata();
        signal DataManagement.initDone(result);
        if (__isBase()) {
            signal DataManagement.newObjComplete();
        }
#else
        signal DataManagement.initDone(result);
#endif
        return;
    }

    command result_t DataManagement.init() { 
        // Clear flash's write-protection in case it was set.
        return call FlashWP.clrWP();
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
                    signalInitDone(FAIL);
                } else {
                    uint16_t crc;
                    crc = call Crc.crc16(&_metadata, 
                        offsetof(ObjMetadata, crcMeta));
                    if (crc != _metadata.crcMeta) {
                        // Metadata corrupted, reset objId.
                        _metadata.objId = 0;
                    }   
                    signalInitDone(SUCCESS);
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

    command uint8_t DataManagement.getNumPagesComplete() {
        return _metadata.numPagesComplete; 
    }

    command uint8_t DataManagement.getNumPktsLastPage() {
        return _metadata.numPktsLastPage;
    }

    command uint8_t DataManagement.getNextIncompletePage() { 
        return _metadata.numPagesComplete; 
    }

    command void DataManagement.setObjMetadata(ObjMetadata * pMetadata) {
        memcpy(&_metadata, pMetadata, sizeof(ObjMetadata));

        dbg(DBG_USR1, "Updating object: ID %d (%d pages, %d packets in last page, CRC=%d)\n", _metadata.objId, _metadata.numPages, _metadata.numPktsLastPage, _metadata.crcData);

        _metadata.numPagesComplete = 0;

        initAllPktsBitVec();

        RX_PKTQ_CLR;
        _state = S_ERASE;
        call BlockWrite.erase();
        return;
    }

    task void writePktTask() {
        RxPktQEntry * entry = &_rxPktQ[_rxPktQHead];
        _state = S_WRITE_PKT;

#ifdef HW_DEBUG
        if (entry->pageId == INVALID_PAGE_ID) {
            call BlockWrite.write(_debugOffset, entry->data, DEBUG_ENTRY_SIZE);
            _debugOffset += DEBUG_ENTRY_SIZE;
            return;
        }
#endif

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
        // It seems BlockWrite does not work in simulation.

        if (isPktReceived(pageId, pktId)) 
            return FAIL; // for the sake of debug message.

        setPktReceived(pageId, pktId);
        checkAndFlushPage(pageId);
        if (_metadata.numPagesComplete == _metadata.numPages) {
            _state = S_IDLE;
            free(_allPktsBitVec); // no longer needed.
            signal DataManagement.newObjComplete();
        }
        return SUCCESS;
#else

        RxPktQEntry * entry = NULL;

        if (isPktReceived(pageId, pktId)) return SUCCESS; // not needed.

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
            setPktReceived(pageId, pktId);
            checkAndFlushPage(pageId);
            if (_state == S_IDLE) post writePktTask();
            return SUCCESS;
        }
#endif
    }

    command result_t DataManagement.readPkt(uint8_t pageId, uint8_t pktId, uint8_t * data) {
        _state = S_READ_PKT;
        call BlockRead.read(getPktOffset(pageId, pktId), data, BYTES_PER_PKT);
        return SUCCESS;
    }

    event void BlockWrite.commitDone(storage_result_t result) { 
        switch (_state) {
            case S_ERASE:
                signal DataManagement.setObjMetadataDone();
                _state = S_IDLE;
                break;
            case S_WRITE_METADATA:
                _state = S_IDLE;
                free(_allPktsBitVec); // no longer needed.
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

    command result_t DataManagement.getPageRecvBitVec(
        uint8_t pageId, uint8_t * bitvec) {

        uint16_t pos = pageId * PKTS_PER_PAGE;
        uint16_t endPos;
        uint16_t i;
 
        if (pageId == (_metadata.numPages - 1)) {
            // Last page.
            endPos = pos + _metadata.numPktsLastPage;
        } else { 
            endPos = pos + PKTS_PER_PAGE; 
        }
        
        memset(bitvec, 0, PKTS_BITVEC_SIZE);
        
        for (i = 0; pos < endPos; pos++, i++) {
            if (BITVEC_GET(_allPktsBitVec, pos) == 0) // not received.
                BITVEC_SET(bitvec, i);
        }
        return SUCCESS;
    }

    command void DataManagement.getObjMetadata(ObjMetadata * pMetadata) {
        memcpy(pMetadata, &_metadata, sizeof(ObjMetadata));
    }

    command result_t DataManagement.writeDebug(uint8_t * data) {
#ifdef HW_DEBUG
        RxPktQEntry * entry = NULL;

        if (_debugOffset >= DEBUG_MAX_OFFSET) return FAIL;

        atomic {
            if (!RX_PKTQ_FULL) {
                entry = &_rxPktQ[_rxPktQTail];
                RX_PKTQ_ADV(_rxPktQTail);
            } 
        }
        if (entry == NULL) {
            return FAIL;
        } else {
            entry->pageId = INVALID_PAGE_ID;
            entry->pktId = INVALID_PKT_ID;
            memcpy(entry->data, data, DEBUG_ENTRY_SIZE);
            if (_state == S_IDLE) post writePktTask();
            return SUCCESS;
        }
#endif
        return SUCCESS;
    }
}


