// $Id: FileWrite.nc,v 1.1.1.1 2007/11/05 19:09:13 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * File reading interface, supports appending writes.
 */

interface FileWrite {
  /**
   * open a file for sequential reads.
   * @param filename Name of file to open. Must not be stack allocated.
   * @param flags: open options, an or (|) of FS_Fxxx constants.<br>
   *   <code>FS_FTRUNCATE</code> Truncate file if it exists<br>
   *   <code>FS_FCREATE</code> Create file if it doesn't exist
   * @return 
   *   SUCCESS: attempt proceeds, <code>opened</code> will be signaled<br>
   *   FAIL: filesystem is busy, another file is already open for writing,
   *     filename is ""
   */
  command result_t open(const char *filename, uint8_t flags);

  /**
   * Signaled at the end of a file open attempt
   * @param fileSize size of file (if file was opened)
   * @param result
   *   FS_OK: file was opened<br>
   *   FS_ERROR_xxx: open failure cause
   * @return Ignored
   */
  event result_t opened(filesize_t fileSize, fileresult_t result);

  /**
   * close file currently open for writing
   * @return
   *   SUCCESS: attempts proceeds, <code>closed</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t close();

  /**
   * Signaled at the end of a file close. File is closed in all cases,
   *   including failure (but in case of failure some data may have been lost).
   * @param result
   *   FS_OK: file was closed without problems. All data has been comitted to
   *     stable storage.<br>
   *   FS_ERROR_xxx: close failure cause
   * @return Ignored
   */
  event result_t closed(fileresult_t result);

  /**
   * Write bytes sequentially to end of open file.
   * @param buffer Data to write
   * @param n Number of bytes to write
   * @return
   *   SUCCESS: attempt proceeds, <code>appended</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t append(void *buffer, filesize_t n);

  /**
   * Signaled when a <code>append</code> completes
   * @param buffer Buffer that was passed to <code>append</code>
   * @param nWritten Number of bytes actually written
   *   but result will still be FS_OK)
   * @param result
   *   FS_OK: write was successful
   *   FS_ERROR_xxx: write failure cause. Some bytes may have been written
   *     (as reported by the value of <code>nWritten</code>
   * @return Ignored
   */
  event result_t appended(void *buffer, filesize_t nWritten,
			  fileresult_t result);

  /**
   * Reserve space for the currently open file to be <code>newSize</code>
   * bytes long. <code>append</code>s that do not make the file take
   * more than <code>newSize</code> bytes will not fail with FS_ERROR_NOSPACE.
   * Note: you can find the reserved size of a file by requesting a reserve
   * with a newSize of 0. The <code>reserved</code> event will indicate the
   * space currently reserved.
   * @param newSize Size file is expected to grow to
   * @return
   *   SUCCESS: attempt proceeds, <code>reserved</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t reserve(filesize_t newSize);

  /**
   * Signaled at the end of a space reservation attempt
   * @param maxSize New reserved size (>= requested size)
   * @param result
   *   FS_OK: space was successfully reserved<br>
   *   FS_ERROR_xxx: failure cause
   * @return Ignored
   */
  event result_t reserved(filesize_t reservedSize, fileresult_t result);

  /**
   * Ensure data appended is comitted to stable storage.
   * @return
   *   SUCCESS: attempt proceeds, <code>synced</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t sync();

  /**
   * Signaled at the end of a sync attempt
   * @param result
   *   FS_OK: sync was successful<br>
   *   FS_ERROR_xxx: failure cause
   * @return Ignored
   */
  event result_t synced(fileresult_t result);
}
