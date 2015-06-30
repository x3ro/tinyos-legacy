/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

includes Flash;
includes FlashFS;

interface FlashFS {

  /*
   * Opens a file for reading or writing.  If the file does not exist and the
   * FFS_O_CREAT flag is set then a new file is created.  The return value is
   * a file descriptor used by the other file io functions or a -1 if there
   * was an error.
   */
  command int open(char *name, int flags);

  /*
   * Moves the read/ write pointer within a file.  The whence flag indicates
   * whether the new location is relative to the beginning, current location,
   * or end of the file.
   */
  command void lseek(int fd, int offset, int whence);

  /*
   * Copy the contents of the file to the buffer and advance the index pointer
   * by size.  The return value is the nuber of bytes read.
   */
  command int read (int fd, char *inbuf, int size);

  /*
   * Copy the contents fo the buffer to the file and advance the index pointer.
   * The return value is the number of bytes copied.
   */
  command int write (int fd, char *outbuf, int size);

  /* 
   * Close the file and commit all of the changes to flash.  The return value
   * is -1 if there was an error.
   */
  command int close (int fd);

  /*
   * Write the in-core contents of the file back to the storage device.
   */

  command int flush (int fd);

  /*
   * Release the storage associated with the file name.  The contents of the
   * file may not be 0'd out.  If an error occurs, -1 is returned.
   */

  command int delete (char *name);

  /*
   * Get a pointer to the inode data structure.  This should only be used to
   * display the contents of the structure.  Any modification of the structure
   * will result in unpredictable behavior.  The parameter next is an index
   * for the next value to return.  To start at the beginning, set next to 0.
   * When the last element is returned, next is set to -1.
   */

  command FInode *getInode(int *next);
}

