// $Id: Matchbox.h,v 1.1.1.1 2007/11/05 19:09:13 jpolastre Exp $

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
#ifndef MATCHBOX_H
#define MATCHBOX_H

// user constants, types for filing system
typedef uint32_t filesize_t;

// Number of files for read and write
enum {
  FS_NUM_RFDS = uniqueCount("FileRead"),
  FS_NUM_WFDS = uniqueCount("FileWrite")
};

enum {
  FS_OK,
  FS_NO_MORE_FILES,
  FS_ERROR_NOSPACE,
  FS_ERROR_BAD_DATA,
  FS_ERROR_FILE_OPEN,
  FS_ERROR_NOT_FOUND,
  FS_ERROR_HW
};

enum {
  FS_FTRUNCATE = 1,
  FS_FCREATE = 2
};

typedef uint8_t fileresult_t;

fileresult_t frcombine(fileresult_t r1, fileresult_t r2)
/* Returns: FAIL if r1 or r2 == FAIL , r2 otherwise. This is the standard
     combining rule for fileresults
*/
{
  return r1 != FS_OK ? r1 : r2;
}

enum {
  FS_CRC_FILES = FALSE
};

#endif
