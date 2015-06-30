// $Id: FileStorage.nc,v 1.1 2006/10/11 00:11:09 lnachman Exp $

/*									tab:2
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
 */

includes Storage;

interface FileStorage 
{
  command result_t fcreate(const uint8_t* filename,
                          storage_addr_t size);

  /**
   * FormatStorage.allocate
   *
   * This is external interface function exposed to the user for allocating 
   * space for a new file.
   * The funciton uses the allocate routine to check for space availability 
   * and makes sure that the file name is unique.
   * If the allocation is successful then the meta data for the newly created 
   * file is added to the uncommited list, waiting for the user to call commit.
   *
   * @param id VolumeId for the new file.
   * @parma size File size in multiples of block size.
   * @param name Name of the new file.
   *
   * @return SUCCESS | FAIL
   */
  command result_t allocate(volume_id_t id, 
                            storage_addr_t size,
                            const uint8_t* name);

  /**
   * FormatStorage.allocateFixed
   *
   * This is a legacy function, it will work but doesnt make
   * the job any easier for the user.
   * FIXME Remove this function if the app doesnt use it.
   *
   * @param id VolumeId for the new file.
   * @parma addr Starting physical address for the file.
   * @parma size File size in multiples of block size.
   *
   * @return SUCCESS | FAIL
   */
  command result_t allocateFixed(volume_id_t id, 
                                 storage_addr_t addr, 
                                 storage_addr_t size);
  /**
   * FormatStorage.commit
   *
   * The file created has to be commited using this function for
   * completing creation of the file.
   *
   * @return SUCCESS | FAIL
   */
  command result_t commit();

  event void commitDone(storage_result_t result);

  /**
   * FormatStorage.fdelete
   *
   * Delete a file by passing its file name as the first parameter. The
   * function clears the entries in the sector table, removes the
   * meta data from the linked list and invalidates the meta data entry
   * for the file. The file blocks are not erased because every create
   * will clean up the blocks during allocation.
   *
   * @param filename Name of the file to be deleted.
   * @return SUCCESS | FAIL
   */
  command result_t fdelete (const uint8_t* filename);

 /**
  * FormatStorage.init
  *
  * This function initalizes the logger file system, by intializing
  * the global variables, the metadata linked list, the sector
  * table block and meta data block.
  *
  * @return SUCCESS | FAIL
  */
  command result_t init();

  /**
   * FileStorage.getNextId
   *
   * Generate the Next Volume id for creating a new file. The current
   * method is to scan through a valid set of id's to identify an
   * unused volume id.
   *
   * @return Unique volume id for file creation.
   */
  command volume_id_t getNextId();

  /**
   * FileStorage.cleanAllFiles
   *
   * The function deletes all the files, cleans the sector table, erases
   * the meta data block and deletes the linked list of valid files.
   * The whole file system is completely reset.
   *
   * @return SUCCESS | FAIL
   */  
  command result_t cleanAllFiles ();

  /**
   * FileStorage.getFileCount
   *
   * Returns the number of valid files in the current context. The
   * function scans the list of valid files to get the count.
   *
   * @return Number of valid files.
   */  
  command volume_id_t getFileCount();

  /**
   * FileStorage.getFileName
   *
   * The function returns the file name of the requested index in
   * the list of valid files. The index must range from 0 - CurrNumFiles.
   * This function is usefull for listing the names of the currently
   * valid files.
   *
   * @param indx Index in the file list, range from 0 - NumFiles.
   *
   * @return SUCCESS | FAIL
   */  
  command char* getFileName(uint16_t indx);

  /**
   * FileStorage.isFileMounted
   *
   * Check if a file is open or closed using its file name.
   * The functions scans the list of valid files and returns
   * the mount status on a name match. If the file name
   * does not exist in the list then it returns TRUE to prevent
   * mounting of a wrong file.
   *
   * FIXME Needs a new error code for unknown file.
   *
   * @param filename Name of the file for which the mount status is required.
   *
   * @return status TRUE | FALSE
   */  
  command bool isFileMounted (const char* filename);

  /**
   * FormatStorage.getSectorTable
   *
   * Sector table is the back bone of the flash logger file system,
   * it keeps track of the correlation between the volumeId and
   * the block number.
   * The sector table is populated during the init process and is
   * used by StorageManger module for different file operations. This
   * function serves as an access routine to get access to the
   * sector table.
   *
   * @return sectorTable The current valid sector table after file system init.
   */
  command SectorTable* getSectorTable();

  /**
   * FormatStorage.getVolumeId
   *
   * The function is more for utility purposes at the higher level since
   * the VolumeId is hidden from the user level. The function returns
   * the volume id of a file given the file name.
   *
   * @param filename Name of the file.
   *
   * @return SUCCESS | FAIL
   */
  command volume_id_t getVolumeId (const uint8_t* filename);

  /**
   * FormatStorage.updateWritePtr
   *
   * This function will update the write pointer in the meta data
   * entry of a particular file. For every write operation the 
   * write pointer is added with the corresponding length and a
   * new entry is added to the meta data block after invalidating
   * the old one for the file. The write pointer is the virtual
   * address of the current write location in the file.
   *
   * @param id VolumeId for the new file.
   * @parma vaddr Current virtual address for writing.
   * @param vlen Length of data written in to the file.
   *
   * @return SUCCESS | FAIL
   */
  command result_t updateWritePtr (volume_id_t id,
                                   storage_addr_t vaddr,
                                   storage_addr_t vlen);

  /**
   * FileStorage.getWritePtr
   *
   * The function returns the current logical address of the write pointer
   * for a given file name. The logical address could range from 0 - Allocated 
   * Size of the file. The logical position also represents the number of
   * bytes written to the file. If the file name does not exist in the
   * valid file list then an INVALID_PTR will be returned.
   *
   * @param filename Name of the file for which the write pointer is requested.
   *
   * @return Current write pointer or INVALID_PTR
   */  
  command storage_addr_t getWritePtr (const uint8_t* filename);

  /**
   * FileStorage.getWritePtr1
   *
   * The function returns the current logical address of the write pointer
   * for a given volume id. The logical address could range from 0 - Allocated 
   * Size of the file. The logical position also represents the number of
   * bytes written to the file. If the requested volme id does not exist in the
   * valid file list then an INVALID_PTR will be returned.
   *
   * @param filename Name of the file for which the write pointer is requested.
   *
   * @return Current write pointer or INVALID_PTR
   */  
  command storage_addr_t getWritePtr1 (volume_id_t id);

  /**
   * FileStorage.getReadPtr
   *
   * The function returns the current read pointer for a give file. Read
   * pointer is a logical position in the file based on the previous read
   * calls and the length of data read. The value of read pointer represents
   * the number of bytes read from the file after the file was opened.
   * If the file name does not exist in the valid file list then an INVALID_PTR
   * will be returned.
   *
   * @parma filename Name of the file for which the read pointer is required.
   *
   * @return Current read pointer of the file or INVALID_PTR
   */
  command storage_addr_t getReadPtr (const uint8_t* filename);

  /**
   * FileStorage.getReadPtr1
   *
   * The function returns the current read pointer for a give file. Read
   * pointer is a logical position in the file based on the previous read
   * calls and the length of data read. The value of read pointer represents
   * the number of bytes read from the file after the file was opened.
   * If the volume id does not exist in the valid file list then an INVALID_PTR
   * will be returned.
   *
   * @parma id VolumeId of the file for which the read pointer is required.
   *
   * @return Current read pointer of the file or INVALID_PTR
   */  
  command storage_addr_t getReadPtr1 (volume_id_t id);

  /**
   * FormatStorage.updateReadPtr
   *
   * The function updates the read pointer of a file in its meta
   * data entry. The read pointer is maintained only in the linked
   * list entry and is not update to the meta data block, it will
   * be reset to 0x0 during reset. The function returns fail if
   * the volume id is invalid.
   *
   * @param id VolumeId for the file.
   * @parma vaddr Current virtual address for reading.
   * @param vlen Length of data read from the file.
   *
   * @return SUCCESS | FAIL
   */
  command result_t updateReadPtr (volume_id_t id,
                                   storage_addr_t vaddr,
                                   storage_addr_t vlen);
}
