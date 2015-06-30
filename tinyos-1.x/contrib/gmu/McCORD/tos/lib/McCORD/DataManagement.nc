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

interface DataManagement {

    command result_t init();

    event void initDone(result_t success);

    command uint16_t getObjId();
 
    command uint16_t getCrcData();

    command uint8_t getNumPages();

    command uint8_t getNumPagesComplete();
 
    command uint8_t getNumPktsLastPage();

    command uint8_t getNextIncompletePage();

    command void setObjMetadata(ObjMetadata * pMetadata);

    event void setObjMetadataDone();
 
    command result_t writePkt(uint8_t pageId, uint8_t pktId, uint8_t * data);

    command result_t readPkt(uint8_t pageId, uint8_t pktId, uint8_t * data);

    event void readPktDone(result_t success);

    event void newObjComplete();

    command result_t getPageRecvBitVec(uint8_t pageId, uint8_t * bitvec);

    command void getObjMetadata(ObjMetadata * pMetadata);

    /**
     * Writes debug information (to the same volume of the data object).
     * @param data an array of 16 bytes.
     */
    command result_t writeDebug(uint8_t * data);
}


