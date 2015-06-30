// $Id: FlashLoggerM.nc,v 1.1 2006/10/11 00:11:09 lnachman Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 *
 * Ported to imote2 by Junaith Ahemed Shahabdeen. The file acts as a user
 * level abstraction for the real implementation of the interfaces.
 * All of the functionalities are actually implemented in SectorStorage
 * module and the FormatStorage module.
 *
 */

module FlashLoggerM 
{
  provides 
  {
    interface FileMount as Mount[blockstorage_t blockId];
    interface FileRead as BlockRead[blockstorage_t blockId];
    interface FileWrite as BlockWrite[blockstorage_t blockId];
  }
  uses 
  {
    interface SectorStorage[blockstorage_t blockId];
    interface FileMount as ActualMount[blockstorage_t blockId];
    interface StorageManager[blockstorage_t blockId];
    interface Leds;
  }
}

implementation 
{
  /*Enumerated values of the states of the flash logger.*/
  enum 
  {
    S_IDLE,
    S_WRITE,
    S_ERASE,
    S_COMMIT,
    S_READ,
    S_VERIFY,
    S_CRC,
  };

  uint8_t state;  /*Current logger state.*/
  uint8_t client; /*Refers to the interface Id*/

  block_addr_t rwAddr, rwLen;
  void* rwBuf;
  uint16_t crc;

  /**
   * Mount.fopen
   *
   * Open a file for read / write by passing file name as the parameter.
   * The function calls mount and commit for a particular file and returns
   * SUCCESS | FAIL. Inorder to access the file it is required to wire
   * the BlockRead and BlockWrite interface with the same blockId as the
   * mount interface.
   *
   * @param filename Name of the file to be opened.
   * @return SUCCESS | FAIL
   */
  command result_t Mount.fopen[blockstorage_t blockId](const uint8_t* filename)
  {
    return call ActualMount.fopen[blockId](filename);
  }

  /**
   * Mount.mount
   *
   * Mount a file for reading / writing. The function takes volumeId of
   * a file as paramter which could be obtained through FormatStorage interface. 
   * It is required to  wire the BlockRead and BlockWrite interface with the 
   * same blockId as the mount interface.
   * 
   * @param id Volume id of a file.
   * @return SUCCESS | FAIL
   */
  command result_t Mount.mount[blockstorage_t blockId](volume_id_t id) 
  {
    return call ActualMount.mount[blockId](id);
  }

  /**
   * Mount.fclose
   *
   */
  command result_t Mount.fclose[blockstorage_t blockId](const uint8_t* filename)
  {
    return call ActualMount.fclose[blockId](filename);
  }  

  /**
   * ActualMount.mountDone
   *
   * Event generated for a mount or an fopen call from the SectorStorage
   * module. The first parameter will be the success code and the second is
   * the volume id of the file.
   * 
   * @param result STORAGE_OK | STORAGE_FAIL
   */
  event void ActualMount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t id) 
  {
    signal Mount.mountDone[blockId](result, id);
  }

  /**
   * signalDone
   *
   * The function generates events to notify the higher lever modules about the
   * completion of a command. The event generated is based on the current stage
   * or the last command invoked, the state variable acts as a semaphore to 
   * prevent over lapping command calls.
   * 
   * @param result STORAGE_OK | STORAGE_FAIL
   */
  void signalDone(storage_result_t result) 
  {
    uint8_t tmpState = state;
    state = S_IDLE;
    switch(tmpState) 
    {
      case S_WRITE: 
        signal BlockWrite.writeDone[client](result, rwAddr, rwBuf, rwLen); 
      break;
      case S_ERASE: 
        signal BlockWrite.eraseDone[client](result); 
        break;
      case S_COMMIT: 
        signal BlockWrite.commitDone[client](result); 
      break;
      case S_READ: 
        signal BlockRead.readDone[client](result, rwAddr, rwBuf, rwLen); 
      break;
      case S_VERIFY: 
        signal BlockRead.verifyDone[client](result); 
      break;
      case S_CRC: 
        signal BlockRead.computeCrcDone[client](result, crc, rwAddr, rwLen); 
      break;
    }
  }

  /**
   * signalDoneTask
   *
   * Delayed task to generate events.
   */
  task void signalDoneTask() 
  {
    signalDone(STORAGE_OK);
  }

  /**
   * newRequest
   *
   * The function is invoked by all of the commands because the book keeping
   * is a common piece. The function invokes the corresponding command
   * in the SectorStorage module based on the current state, where the real
   * work is done. On successful return from SectorStorage the current
   * state is changed from S_IDLE to prevent any new commands.
   *
   * @param newState The current state is the current command defined in the enm.
   * @param blockId  The interface Id.
   * @param addr     Logical address within the file.
   * @param buf      Required if it is a read or write command. Basically data buffer.
   * @param len      Length of the buffer.
   *
   * @return SUCCESS | FAIL
   */
  result_t newRequest(uint8_t newState, blockstorage_t blockId, 
                      block_addr_t addr, void* buf, block_addr_t len) 
  {
    result_t result = FAIL;

    if (state != S_IDLE)
      return FAIL;

    client = blockId;

    rwAddr = addr;
    rwBuf = buf;
    rwLen = len;

    switch(newState) 
    {
      case S_READ:
        result = call SectorStorage.read[blockId](rwAddr, rwBuf, rwLen);
      break;
      case S_CRC:
        result = call SectorStorage.computeCrc[blockId](&crc, 0, rwAddr, rwLen);
      break;
      case S_VERIFY:
      break;
      case S_WRITE:
        result = call SectorStorage.write[blockId](rwAddr, rwBuf, rwLen);
      break;
      case S_ERASE:
        result = call SectorStorage.erase[blockId](0, 
                            call StorageManager.getNumSectors[blockId]());
      break;
      case S_COMMIT:
        result = SUCCESS;
      break;
    }

    if (newState == S_READ || newState == S_CRC || 
        newState == S_COMMIT || newState == S_VERIFY) 
    {
      if (result == SUCCESS) 
        result = post signalDoneTask();
    }

    if (result == SUCCESS)
      state = newState;

    return result;
  }
  
  /**
   * BlockRead.getSize
   * 
   * The function returns the size of the currently mounted file. The
   * function calls getVolumeSize of SectorStorage which calculate
   * the file size based on the number of blocks allocated to the file.
   *
   * @return size The size of the file.
   */
  command uint32_t BlockRead.getSize[blockstorage_t blockId]() 
  {
    return call StorageManager.getVolumeSize[blockId]();
  }

  /**
   * BlockRead.getReadPtr
   *
   * Function returns the current read pointer for the mounted
   * file. Note that the read pointer is a ram variable and will
   * be automatically reset when the system restarts.
   *
   * @return readPtr Logical address of the Read Pointer.
   */
  command block_addr_t BlockRead.getReadPtr[blockstorage_t blockId] ()
  {
    return call SectorStorage.getReadPtr[blockId]();
  }

  /**
   * BlockRead.resetReadPtr
   *
   * Reset the logical address of the read pointer to 0x0 for the
   * file mounted using blockId.
   *
   * @return SUCCESS | FAIL
   */
  command result_t BlockRead.resetReadPtr[blockstorage_t blockId] ()
  {
    return call SectorStorage.resetReadPtr[blockId]();
  }

  /**
   * BlockRead.rseek
   *
   * Move the read pointer to a given location within the file. The
   * first parameter should range from 0x0 to Size_of_file.
   *
   * @param addr Virtual address ranging from 0x0 to SIZE_OF_FILE
   * 
   * @return SUCCESS | FAIL
   */
  command result_t BlockRead.rseek[blockstorage_t blockId] (block_addr_t addr)
  {
    return call SectorStorage.rseek[blockId](addr);
  }

  /**
   * BlockRead.fread
   *
   * Read data from the mounted file and store it in buf. It is required
   * that the caller should allocate enough memory for <I>buf</I> to hold
   * data of size <I>len</I>. The read starts from the current read pointer
   * location.
   *
   * @param buf Buffer in which the file data will be stored.
   * @param len Number of bytes to be read from the file.
   *
   * @return SUCCESS | FAIL
   */
  command result_t BlockRead.fread[blockstorage_t blockId](void* buf, 
                                                           block_addr_t len) 
  {
    result_t res = FAIL;

    client = blockId;
    rwAddr = 0x0;
    rwBuf = buf;
    rwLen = len;
    state = S_READ;
    res = call SectorStorage.fread[blockId](buf, len);
    if (res == SUCCESS)
      signalDone(STORAGE_OK);
    else
      signalDone(STORAGE_FAIL);
    return res;
  }
  
  /**
   * BlockRead.read
   *
   * Read data from the mounted file and store it in buf. It is required
   * that the caller should allocate enough memory for <I>buf</I> to hold
   * data of size <I>len</I>.
   * The starting logical address has to be passed as the first parameter.
   *
   * @param addr Virtual address ranging from 0x0 to SIZE_OF_FILE
   * @param buf Buffer in which the file data will be stored.
   * @param len Number of bytes to be read from the file.
   * 
   * @return SUCCESS | FAIL
   */
  command result_t BlockRead.read[blockstorage_t blockId](block_addr_t addr, 
                                                void* buf, block_addr_t len) 
  {
    return newRequest(S_READ, blockId, addr, buf, len);
  }

  /**
   * BlockRead.verify
   *
   * NOTE IMPLEMENTED
   * FIXME Should be removed.
   */
  command result_t BlockRead.verify[blockstorage_t blockId]() 
  {
    return newRequest(S_VERIFY, blockId, 0, NULL, 0);
  }

  /**
   * BlockRead.computeCrc
   * 
   * Compute CRC of a given section of the file or the whole file based on
   * <I>addr</I> and <I>len</I>.
   * 
   * @return SUCCESS | FAIL
   */
  command result_t BlockRead.computeCrc[blockstorage_t blockId](block_addr_t addr,
                                                                block_addr_t len) 
  {
    return newRequest(S_CRC, blockId, addr, NULL, len);
  }

  /**
   * BlockWrite.erase
   *
   * The blocks allocated for the file will be erased and the write pointer will
   * be set to 0x0. This is useful if a file has to be reused with new data because
   * the current implementation does not allow the manipulation of already used
   * space in a file.
   * 
   * @return SUCCESS | FAIL
   */
  command result_t BlockWrite.erase[blockstorage_t blockId]() 
  {
    return newRequest(S_ERASE, blockId, 0, NULL, 0);
  }

  /**
   * BlockWrite.append
   *
   * Data from <I>buf</I> is appended to a mounted file for given length <I>len</I>.
   * Current write pointer will be used as the logical starting address. len + 
   * currWritePtr should be less than the size of the file or the funtion will
   * return an error.
   * The function performs the book keeping locally and changes the state to
   * S_WRITE.
   *
   * @param buf Buffer contaning data to be written to the file.
   * @param len Number of bytes to be written to the file.
   *  
   * @return SUCCESS | FAIL
   */
  command result_t BlockWrite.append[blockstorage_t blockId] (void* buf, 
                                                              block_addr_t len)
  {
    result_t res = FAIL;
    client = blockId;
    rwAddr = 0x0;
    rwBuf = buf;
    rwLen = len;
    state = S_WRITE; 
    res = call SectorStorage.append[blockId](buf, len);
    if (res == FAIL)
      signalDone(STORAGE_FAIL);
    return res;
  }

  /**
   * BlockWrite.write
   * 
   * Data from <I>buf</I> is written to a mounted file for given length <I>len</I>.
   * The logical starting address should be passed as the first parameter to the
   * function. addr + len should be less than the size of the file or the funtion will
   * return an error.
   *
   * @param addr Virtual address ranging from 0x0 to SIZE_OF_FILE
   * @param buf Buffer contaning data to be written to the file.
   * @param len Number of bytes to be written to the file.
   *  
   * @return SUCCESS | FAIL
   */
  command result_t BlockWrite.write[blockstorage_t blockId](block_addr_t addr, 
                                                   void* buf, block_addr_t len) 
  {
    return newRequest(S_WRITE, blockId, addr, buf, len);
  }

  /**
   * BlockWrite.commit
   * 
   * NOT IMPLEMENTED. DOES NOT HAVE ANY EFFECT.
   * FIXME Should be removed.
   */
  command result_t BlockWrite.commit[blockstorage_t blockId]() 
  {
    return newRequest(S_COMMIT, blockId, 0, NULL, 0);
  }

  /**
   * BlockWrite.getWritePtr
   *
   * The function returns the current write pointer for the mounted
   * file.
   *
   * @return WritePtr Current logical address for writing or Write Pointer.
   *
   * @return SUCCESS | FAIL
   */
  command block_addr_t BlockWrite.getWritePtr[blockstorage_t blockId]()
  {
    return call SectorStorage.getWritePtr[blockId]();
  }

  /**
   * BlockWrite.resetWritePtr
   *
   * The function will reset the write pointer to 0x0. This is essentially
   * same as erasing the file as resetting the write pointer will allow
   * write operation starting from 0x0, which in turn means that the 
   * blocks has to be prepared for writing new data.
   *
   * NOTE - The content of the file will be lost.
   *
   * @return SUCCESS | FAIL
   */
  command result_t BlockWrite.resetWritePtr[blockstorage_t blockId]()
  {
    return call SectorStorage.resetWritePtr[blockId]();
  }
  
  /**
   * SectorStorage.writeDone
   *
   * Event generated by StorageManager module to notify that the
   * write request is completed.
   *
   * @param result STORAGE_OK | STORAGE_FAIL
   */
  event void SectorStorage.writeDone[blockstorage_t blockId]
                                                 (storage_result_t result) 
  {
    signalDone(result);
  }
  
  /**
   * SectorStorage.eraseDone
   *
   * Event generated by StorageManager module to notify that the
   * erase request is completed.
   *
   * @param result STORAGE_OK | STORAGE_FAIL
   */  
  event void SectorStorage.eraseDone[blockstorage_t blockId]
                                                 (storage_result_t result) 
  {
    signalDone(result);
  }

  default event void BlockWrite.writeDone[blockstorage_t blockId]
                                                 (storage_result_t result, 
                                                  block_addr_t addr, 
                                                  void* buf, 
                                                  block_addr_t len) 
  { ; }

  default event void BlockWrite.eraseDone[blockstorage_t blockId]
                                             (storage_result_t result) 
  { ; }

  default event void BlockWrite.commitDone[blockstorage_t blockId]
                                             (storage_result_t result) 
  { ; }

  default event void BlockRead.readDone[blockstorage_t blockId]
                                             (storage_result_t result, 
                                              block_addr_t addr, 
                                              void* buf, 
                                              block_addr_t len) 
  { ; }

  default event void BlockRead.verifyDone[blockstorage_t blockId]
                                                (storage_result_t result) 
  { ; }

  default event void BlockRead.computeCrcDone[blockstorage_t blockId]
                                                 (storage_result_t result, 
                                                  uint16_t crcResult, 
                                                  block_addr_t addr, 
                                                  block_addr_t len) 
  { ; }

  default event void Mount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t id) { ; }

}
