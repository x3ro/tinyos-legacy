// $Id: BlockStorageM.nc,v 1.1.1.1 2007/11/05 19:09:11 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author: David Gay <dgay@acm.org>
 */

includes Storage;
#define HALAT45DB PageEEPROM
includes BlockStorage;

module BlockStorageM {
  provides {
    interface Mount[blockstorage_t blockId];
    interface BlockWrite[blockstorage_t blockId];
    interface BlockRead[blockstorage_t blockId];
  }
  uses {
    interface HALAT45DB[blockstorage_t blockId];
    interface Mount as ActualMount[blockstorage_t blockId];
    interface AT45Remap;
  }
}
implementation 
{
  enum {
    S_IDLE,
    S_WRITE,
    S_ERASE,
    S_COMMIT, S_COMMIT2, S_COMMIT3,
    S_READ,
    S_VERIFY, S_VERIFY2,
    S_CRC,
  };

  uint8_t state = S_IDLE;
  uint8_t client;

  uint8_t* bufPtr;
  block_addr_t curAddr;
  block_addr_t bytesRemaining, requestedLength;
  uint16_t crc;
  block_addr_t maxAddr[uniqueCount("StorageManager")];
  uint8_t sig[8];

  void verifySignature();
  void commitSignature();
  void commitSync();

  result_t actualSignal(storage_result_t result) {
    uint8_t tmpState = state;
    block_addr_t actualLength;

    state = S_IDLE;
    actualLength = requestedLength - bytesRemaining;
    curAddr -= actualLength;
    bufPtr -= actualLength;

    switch(tmpState)
      {
      case S_READ:
	signal BlockRead.readDone[client](result, curAddr, bufPtr, actualLength);
	break;
      case S_WRITE:
	signal BlockWrite.writeDone[client](result, curAddr, bufPtr, actualLength);
	break;
      case S_ERASE:
	signal BlockWrite.eraseDone[client](result);
	break;
      case S_CRC:
	signal BlockRead.computeCrcDone[client](result, crc, curAddr, actualLength);
	break;
      case S_COMMIT: case S_COMMIT2: case S_COMMIT3:
	signal BlockWrite.commitDone[client](result);
	break;
      case S_VERIFY: case S_VERIFY2: 
	signal BlockRead.verifyDone[client](result);
	break;
      }

    return SUCCESS;
  }

  task void signalSuccess() { actualSignal(STORAGE_OK); }
  
  task void signalFail() { actualSignal(STORAGE_FAIL); }

  void signalDone(result_t result) {
    if (result == SUCCESS)
      switch (state)
	{
	case S_COMMIT: commitSignature(); break;
	case S_COMMIT2: commitSync(); break;
	case S_VERIFY: verifySignature(); break;
	case S_VERIFY2: 
	  if (crc == (sig[0] | (uint16_t)sig[1] << 8))
	    actualSignal(STORAGE_OK);
	  else
	    actualSignal(STORAGE_INVALID_CRC);
	  break;
	default: post signalSuccess(); break;
	}
    else
      post signalFail();
  }

  void check(result_t ok) {
    if (!ok)
      post signalFail();
  }

  bool admitRequest(uint8_t newState, uint8_t id) {
    if (state != S_IDLE)
      return FALSE;
    client = id;
    state = newState;
    return TRUE;
  }

  void calcRequest(block_addr_t addr, at45page_t *page,
		   at45pageoffset_t *offset, at45pageoffset_t *count) {
    *page = addr >> AT45_PAGE_SIZE_LOG2;
    *offset = addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1);
    if (bytesRemaining < (1 << AT45_PAGE_SIZE_LOG2) - *offset)
      *count = bytesRemaining;
    else
      *count = (1 << AT45_PAGE_SIZE_LOG2) - *offset;
  }

  void continueRequest() {
    at45page_t page;
    at45pageoffset_t offset, count;
    uint8_t *buf = bufPtr;

    calcRequest(curAddr, &page, &offset, &count);
    bytesRemaining -= count;
    curAddr += count;
    bufPtr += count;

    switch (state)
      {
      case S_WRITE:
	check(call HALAT45DB.write[client](page, offset, buf, count));
	break;
      case S_READ:
	check(call HALAT45DB.read[client](page, offset, buf, count));
	break;
      case S_CRC: case S_COMMIT: case S_VERIFY2:
	check(call HALAT45DB.computeCrcContinue[client](page, offset, count, crc));
	break;
      }
  }

  result_t newRequest(uint8_t newState, uint8_t id,
		       block_addr_t addr, uint8_t* buf, block_addr_t len) {
    if (admitRequest(newState, id) == FAIL)
      return FAIL;

    curAddr = addr;
    bufPtr = buf;
    bytesRemaining = requestedLength = len;
    crc = 0;

    continueRequest();

    return SUCCESS;
  }

  command result_t BlockWrite.write[uint8_t id](block_addr_t addr, void* buf, block_addr_t len) {
    result_t ok = newRequest(S_WRITE, id, addr, buf, len);

    if (ok && addr + len > maxAddr[id])
      maxAddr[id] = addr+len;

    return ok;
  }

  command result_t BlockWrite.erase[uint8_t id]() {
    if (admitRequest(S_ERASE, id) == FAIL)
      return FAIL;

    check(call HALAT45DB.erase[client](0, AT45_ERASE));

    return SUCCESS;
  }

  command result_t BlockWrite.commit[uint8_t id]() {
    return newRequest(S_COMMIT, id, 0, NULL, maxAddr[id]);
  }

  /* Called once crc computed. Write crc + signature in block 0. */
  void commitSignature() {
    sig[0] = crc;
    sig[1] = crc >> 8;
    sig[2] = maxAddr[client];
    sig[3] = maxAddr[client] >> 8;
    sig[4] = maxAddr[client] >> 16;
    sig[5] = maxAddr[client] >> 24;
    sig[6] = 0xb1; /* block sig: b10c */
    sig[7] = 0x0c;
    state = S_COMMIT2;
    /* Note: bytesRemaining is 0, so multipageDone will go straight to
       signalDone */
    check(call HALAT45DB.write[client](0, 1 << AT45_PAGE_SIZE_LOG2, sig, sizeof sig));
  }

  /* Called once signature written. Ensure writes complete. */
  void commitSync() {
    state = S_COMMIT3;
    check(call HALAT45DB.syncAll[client]());
  }

  command uint32_t BlockRead.getSize[blockstorage_t blockId]() {
    return call AT45Remap.volumeSize(blockId);
  }

  command result_t BlockRead.read[uint8_t id](block_addr_t addr, void* buf, block_addr_t len) {
    return newRequest(S_READ, id, addr, buf, len);
  }

  command result_t BlockRead.verify[uint8_t id]() {
    if (admitRequest(S_VERIFY, id))
      {
	bytesRemaining = 0;
	check(call HALAT45DB.read[client](0, 1 << AT45_PAGE_SIZE_LOG2, sig, sizeof sig));
      }
    return SUCCESS;
  }

  /* See commitSignature */
  void verifySignature() {
    if (sig[6] == 0xb1 && sig[7] == 0x0c)
      {
	maxAddr[client] = sig[2] | (uint32_t)sig[3] << 8 |
	  (uint32_t)sig[4] << 16 | (uint32_t)sig[5] << 24;
	state = S_IDLE;
	newRequest(S_VERIFY2, client, 0, NULL, maxAddr[client]);
      }
    else
      actualSignal(STORAGE_INVALID_SIGNATURE);
  }

  command result_t BlockRead.computeCrc[uint8_t id](block_addr_t addr, block_addr_t len) {
    return newRequest(S_CRC, id, addr, NULL, len);
  }

  void multipageDone(result_t result) {
    if (bytesRemaining == 0 || result == FAIL)
      signalDone(result);
    else
      continueRequest();
  }

  event result_t HALAT45DB.writeDone[uint8_t id](result_t result) {
    if (id == client)
      multipageDone(result);
    return SUCCESS;
  }

  event result_t HALAT45DB.readDone[uint8_t id](result_t result) {
    if (id == client)
      multipageDone(result);
    return SUCCESS;
  }

  event result_t HALAT45DB.computeCrcDone[uint8_t id](result_t result, uint16_t newCrc) {
    if (id == client)
      {
	crc = newCrc;
	multipageDone(result);
      }
    return SUCCESS;
  }

  event result_t HALAT45DB.eraseDone[uint8_t id](result_t result) {
    if (id == client)
      signalDone(result);
    return SUCCESS;
  }

  event result_t HALAT45DB.syncDone[uint8_t id](result_t result) {
    if (id == client)
      signalDone(result);
    return SUCCESS;
  }

  event result_t HALAT45DB.flushDone[uint8_t id](result_t result) {
    return SUCCESS;
  }

  default event void BlockWrite.writeDone[uint8_t id](storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) { }
  default event void BlockWrite.eraseDone[uint8_t id](storage_result_t result) { }
  default event void BlockWrite.commitDone[uint8_t id](result_t result) { }
  default event void BlockRead.readDone[uint8_t id](storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) { }
  default event void BlockRead.verifyDone[uint8_t id](result_t result) { }
  default event void BlockRead.computeCrcDone[uint8_t id](storage_result_t result, uint16_t x, block_addr_t addr, block_addr_t len) { }

  command result_t Mount.mount[blockstorage_t blockId](volume_id_t volid) {
    maxAddr[blockId] = 0;
    return call ActualMount.mount[blockId](volid);
  }

  event void ActualMount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t volid) {
    signal Mount.mountDone[blockId](result, volid);
  }

  default event void Mount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t id) {
  }
}
