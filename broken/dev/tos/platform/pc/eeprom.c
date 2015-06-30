/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: eeprom.c
 * AUTHOR: Philip Levis <pal@cs.berkeley.edu>
 *   DESC: A flat, segmented address space for LOGGER emulation.
 */

#include <string.h> // For memcpy(3)
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

static char* filename;
static int numMotes = 0;
static int moteSize = 0;
static int initialized = 0;
static int fd = -1;

int createEEPROM(char* file, int motes, int eempromBytes) {
  int rval;
  char val = 0;
  
  filename = file;
  numMotes = motes;
  moteSize = eempromBytes;
  
  if (initialized) {
    dbg(DBG_ERROR, "ERROR: Trying to initialize EEPROM twice.\n");
    return -1;
  }
  fd = open(file, O_RDWR | O_CREAT, S_IRWXU | S_IRGRP | S_IROTH);

  if (fd < 0) {
    dbg(DBG_ERROR, "ERROR: Unable to create EEPROM backing store file.\n");
    return -1;
  }

  rval = (int)lseek(fd, (moteSize * numMotes), SEEK_SET);
  if (rval < 0) {
    dbg(DBG_ERROR, "ERROR: Unable to establish EEPROM of correct size.\n");
  }

  rval = write(fd, &val, 1);
  if (rval < 0) {
    dbg(DBG_ERROR, "ERROR: Unable to establish EEPROM of correct size.\n");
  }
  initialized = 1;
  
  return fd;
}

int anonymousEEPROM(int fnumMotes, int eepromSize) {
  int filedes;
  filedes = createEEPROM("/tmp/anonymous", fnumMotes, eepromSize);
  if (filedes >= 0) {
    unlink("/tmp/anonymous");
    return 0;
  }
  else {
    dbg(DBG_ERROR, "ERROR: Unable to create anonymous EEPROM region.\n");
    return -1;
  }
}

int namedEEPROM(char* name, int fnumMotes, int eepromSize) {
  int filedes = createEEPROM(name, fnumMotes, eepromSize);
  if (filedes >= 0) {
    return 0;
  }
  else {
    dbg(DBG_ERROR, "ERROR: Unable to create named EEPROM region: %s.\n", name);
    return -1;
  }
}

int readEEPROM(char* buffer, int mote, int offset, int length) {
  // Sanity check arguments; don't want to corrupt data.
  if (mote > numMotes || mote < 0) {
    dbg(DBG_ERROR, "ERROR: Tried to read EEPROM of mote %i when it was initialized for only %i motes.\n", mote, numMotes);
    return -1;
  }
  else if ((offset + length) > moteSize) {
    dbg(DBG_ERROR, "ERROR: Tried to read EEPROM address 0x%x of mote when its max EEPROM address is 0x%x.\n", (offset + length), moteSize);
    return -1;
  }
  else if (length < 0 || offset < 0) {
    dbg(DBG_ERROR, "ERROR: Both length and offset for EEPROM reads must be > 0.\n");
    return -1;
  }
  else {
    int rval;
    int startOffset = mote * moteSize;
    int seekedOffset = startOffset + offset;
    rval = lseek(fd, seekedOffset, SEEK_SET);
    if (rval < 0) {
      dbg(DBG_ERROR, "ERROR: Seek in EEPROM for read failed.\n");
    }
    rval = read(fd, buffer, length);
    if (rval <= 0) {
      dbg(DBG_ERROR, "ERROR: Read for %i from EEPROM failed: %s.\n", length, strerror(errno));
    }
    return 0;
  }
}

int writeEEPROM(char* buffer, int mote, int offset, int length) {
  // Sanity check arguments; don't want to corrupt data.
  if (mote > numMotes || mote < 0) {
    dbg(DBG_ERROR, "ERROR: Tried to write EEPROM of mote %i when it was initialized for only %i motes.\n", mote, numMotes);
    return -1;
  }
  else if ((offset + length) > moteSize) {
    dbg(DBG_ERROR, "ERROR: Tried to write EEPROM address 0x%x of mote when its max EEPROM address is 0x%x.\n", (offset + length), moteSize);
    return -1;
  }
  else if (length < 0 || offset < 0) {
    dbg(DBG_ERROR, "ERROR: Both length and offset for EEPROM write must be > 0.\n");
    return -1;
  }
  else {
    int rval;
    int startOffset = mote * moteSize;
    int seekedOffset = startOffset + offset;
    rval = lseek(fd, seekedOffset, SEEK_SET);
    if (rval < 0) {
      dbg(DBG_ERROR, "ERROR: Seek in EEPROM for write failed: %s.\n", strerror(errno));
    }
    rval = write(fd, buffer, length);
    if (rval <= 0) {
      dbg(DBG_ERROR, "ERROR: Write to EEPROM failed: %s.\n", strerror(errno));
    }
    return 0;
  }
}

int syncEEPROM() {
  return fsync(fd);
}
