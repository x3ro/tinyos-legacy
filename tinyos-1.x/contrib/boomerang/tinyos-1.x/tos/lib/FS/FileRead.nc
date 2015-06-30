// $Id: FileRead.nc,v 1.1.1.1 2007/11/05 19:09:13 jpolastre Exp $

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
 * File reading interface, supports sequential reads.
 */

interface FileRead {
  /**
   * open a file for sequential reads.
   * @param filename Name of file to open. Must not be stack allocated.
   * @return 
   *   SUCCESS: attempt proceeds, <code>opened</code> will be signaled<br>
   *   FAIL: filesystem is busy or another file is open for reading
   */
  command result_t open(const char *filename);

  /**
   * Signaled at the end of a file open attempt
   * @param result
   *   FS_OK: file was opened<br>
   *   FS_ERROR_xxx: open failure cause
   * @return Ignored
   */
  event result_t opened(fileresult_t result);

  /**
   * Close file currently open for reading
   * @return SUCCESS if a file was open, FAIL otherwise
   */
  command result_t close();

  /**
   * Read bytes sequentially from open file.
   * @param buffer Target to read into
   * @param n Number of bytes to read
   * @return
   *   SUCCESS: attempt proceeds, <code>readDone</code> will be signaled<br>
   *   FAIL: no file was open for reading, or a read is in progress
   */
  command result_t read(void *buffer, filesize_t n);

  /**
   * Signaled when a <code>read</code> completes
   * @param buffer Buffer that was passed to <code>read</code>
   * @param nRead Number of bytes actually read ,
   *   but result will still be FS_OK)
   * @param result
   *   FS_OK: read was successful (if end-of-file is reached,
   *    <code>nRead</code> will be less than the number of bytes requested)<br>
   *   FS_ERROR_xxx: read failure cause.
   * @return Ignored
   */
  event result_t readDone(void *buffer, filesize_t nRead,
			  fileresult_t result);

  /**
   * Return number of bytes remaining in file.
   * @return
   *   SUCCESS: attempt proceeds, <code>remaining</code> will be signaled<br>
   *   FAIL: no file was open for reading, or a read is in progress
   */
  command result_t getRemaining();

  /**
   * Signaled when <code>getRemaining</code> completes
   * @param n Number of bytes remaining in file
   * @param result
   *   FS_OK: operation was successful
   *   FS_ERROR_xxx: read failure cause
   * @return Ignored
   */
  event result_t remaining(filesize_t n, fileresult_t result);
}
