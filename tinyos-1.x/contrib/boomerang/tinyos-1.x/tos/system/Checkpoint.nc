// $Id: Checkpoint.nc,v 1.1.1.1 2007/11/05 19:10:41 jpolastre Exp $

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

/*
 * checkpoint.c - provide a reliable checkpoint to eeprom facility
 *
 * Authors: David Gay
 * History: created 12/19/01
 */

/**
 * Reliable checkpointing to the (offchip) onboard flash
 * @author David Gay
 */

module Checkpoint 
{
  provides {
    interface CheckpointInit;
    interface CheckpointRead;
    interface CheckpointWrite;
  }
  uses {
    interface EEPROMRead;
    interface EEPROMWrite;
    interface StdControl as EEPROMControl;
  }
}
implementation
{

  enum {
    COOKIE = 0x6f776c73,	/* owls */
    MAX_DATA_SETS = TOS_EEPROM_LINE_SIZE
  };

  uint16_t eepromBase;
  uint16_t dataLength;
  uint8_t ndataSets;
  uint8_t noHeader;

  uint8_t currentIndex;
  uint8_t freeDataSet;
  uint8_t index[MAX_DATA_SETS];

  uint8_t eepromLine[TOS_EEPROM_LINE_SIZE];
  uint8_t *readDest;

  uint8_t *userData;
  uint16_t userBytes;
  uint16_t userLine;
  result_t writeResult;

  enum { s_init, 
	 s_load_config_1, s_load_config_2, s_load_config_3,
         s_ready,
	 s_reading,
	 s_writing, s_writing_index, s_writing_selector, s_writing_header }
  state;

  /* The organisation in the EEPROM is as follows:
     There's a 4 line header, followed by nDataSets+1 storage slots for the
     nDataSet checkpointable items. Only nDataSets of the slots are in use
     at any time (each slot takes (dataLength + 15)/16 EEPROM lines).

     line 0: header (struct header below)
     line 1: 0 if current index is line 2, non-zero if it is line 3
     line 2 or 3: index: an array indexed by item number indicating the
       slot in which that item is stored.
       Unused parts of the index are set to 42.

     During checkpoint writes, the new value for item i is written to the
     free slot, a new index reflecting this change is written to the index
     line that is not in use, then finally line 1 is updated to indicate the
     new index.

     This scheme guarantees atomicity of checkpoints.
  */
  enum {
    HEADER_OFFSET = 0,
    SELECTOR_OFFSET = 1,
    INDEX_OFFSET = 2,
    DATA_OFFSET = 4
  };

  struct header {
    uint32_t cookie;		/* Magic cookie to recognise checkpoint info */
    /* next two values must match call to init */
    uint8_t ndataSets;
    uint16_t dataLength;
  };

  void setState(int n) {
    state = n;
    /*dbgn(n);*/
  }

  uint16_t linesPerSet(uint16_t dlen) {
    return (dlen + TOS_EEPROM_LINE_SIZE - 1) / TOS_EEPROM_LINE_SIZE;
  }

  /* No valid checkpoint state found */
  void clearData() {
    uint8_t i;

    setState(s_ready);
    currentIndex = 0;
    freeDataSet = ndataSets;
    noHeader = TRUE;

    for (i = 0; i < ndataSets; i++)
      index[i] = i;
    for (; i < MAX_DATA_SETS; i++)
      index[i] = 42;

    signal CheckpointInit.initialised(TRUE);
  }

  /* Load the checkpoint meta-data */
  void headerRead(uint8_t n, uint8_t *to) {
    readDest = to;
    if (!call EEPROMRead.read(eepromBase + n, to))
      clearData();
  }

  void loadConfig() {
    setState(s_load_config_1);
    headerRead(HEADER_OFFSET, eepromLine);
  }

  void loadConfig1() {
    struct header *config = (struct header *)eepromLine;

    if (config->cookie != COOKIE ||
	config->ndataSets != ndataSets ||
	config->dataLength != dataLength)
      {
	clearData();
      }
    else
      {
	setState(s_load_config_2);
	headerRead(SELECTOR_OFFSET, eepromLine);
      }
  }

  void loadConfig2() {
    setState(s_load_config_3);
    currentIndex = eepromLine[0] != 0;
    headerRead(INDEX_OFFSET + currentIndex, index);
  }

  void loadConfig3() {
#if MAX_DATA_SETS >= 31
#error Code below limited to 31 data sets
#endif

    uint32_t freeSets = (1 << (ndataSets + 1)) - 1;
    uint8_t i, bitcount;
    bool valid = TRUE;
    uint8_t *line = index;
    uint8_t nsets = ndataSets;

    for (i = 0; i < nsets; i++)
      if (line[i] > nsets)
	valid = FALSE;
      else
	freeSets &= ~(1 << line[i]);

    /* More sanity checking, unused entries should be 42 */
    for (; i < MAX_DATA_SETS; i++)
      if (line[i] != 42)
	valid = FALSE;

    /* Should be only one free bit in freeSets */
    bitcount = 0;
    for (i = 0; i <= nsets; i++)
      if (freeSets & (1 << i))
	{
	  bitcount++;
	  freeDataSet = i;
	}

    if (bitcount != 1)
      valid = FALSE;

    if (!valid)
      {
	clearData();
      }
    else
      {
	setState(s_ready);
	noHeader = FALSE;
	signal CheckpointInit.initialised(FALSE);
      }
  }

  command result_t CheckpointInit.init(uint16_t ebase,
				       uint16_t dlen,
				       uint8_t nsets) {
    unsigned int nlinesPerSet;

    setState(s_init);

    eepromBase = ebase;
    ndataSets = nsets;
    dataLength = dlen;

    if (ndataSets >= MAX_DATA_SETS)
      return FAIL;

    /* Truly egregious values will overflow */
    nlinesPerSet = linesPerSet(dlen);
    if (eepromBase + 4 + nlinesPerSet * (ndataSets + 1) > TOS_EEPROM_MAX_LINES)
      return FAIL;

    if (!call EEPROMControl.init())
      return FAIL;

    loadConfig();
    return SUCCESS;
  }

  void readEnd(result_t success) {
    setState(s_ready);
    signal CheckpointRead.readDone(success, userData + userBytes - dataLength);
  }

  /* Read a checkpointed item, line by line */

  void startNextRead() {
    readDest = eepromLine;
    if (!call EEPROMRead.read(userLine, readDest))
      readEnd(FAIL);
  }

  void processRead() {
    if (userBytes < TOS_EEPROM_LINE_SIZE)
      {
	memcpy(userData, readDest, userBytes);
	readEnd(SUCCESS);
      }
    else
      {
	memcpy(userData, readDest, TOS_EEPROM_LINE_SIZE);
	userData += TOS_EEPROM_LINE_SIZE;
	userBytes -= TOS_EEPROM_LINE_SIZE;
	userLine++;
	startNextRead();
      }
  }

  command result_t CheckpointRead.read(uint8_t data_set, uint8_t *data) {
    if (state != s_ready || data_set >= ndataSets)
      return FAIL;

    userData = data;
    userBytes = dataLength;
    userLine = eepromBase + DATA_OFFSET +
      index[data_set] * linesPerSet(dataLength);
    setState(s_reading);
    startNextRead();

    return SUCCESS;
  }

  event result_t EEPROMRead.readDone(uint8_t *buffer, result_t success) {
    if (buffer == readDest)
      {
	if (success)
	  switch (state)
	    {
	    case s_load_config_1:
	      loadConfig1();
	      break;
	    case s_load_config_2:
	      loadConfig2();
	      break;
	    case s_load_config_3:
	      loadConfig3();
	      break;
	    case s_reading:
	      processRead();
	    default:
	      /* BUG */
	      break;
	    }
	else
	  switch (state)
	    {
	    case s_load_config_1: case s_load_config_2: case s_load_config_3:
	      clearData();
	      break;
	    case s_reading:
	      readEnd(FAIL);
	      break;
	    default:
	      /* BUG */
	      break;
	    }
      }
    return SUCCESS;
  }

  /* Write checkpointed item, line by line */

  result_t writeFinished() {
    noHeader = FALSE;
    setState(s_ready);
    return 
      signal CheckpointWrite.writeDone(writeResult,
				       userData + userBytes - dataLength);
  }

  event result_t EEPROMWrite.endWriteDone(result_t success) {
    writeResult = rcombine(writeResult, success);
    return writeFinished();
  }

  void endWrite() {
    if (!call EEPROMWrite.endWrite())
      {
	writeResult = FAIL;
	writeFinished();
      }
  } 

  void headerWrite(uint8_t n, uint8_t *data) {
    if (!call EEPROMWrite.write(eepromBase + n, data))
      {
	writeResult = FAIL;
	endWrite();
      }
  }

  void commitWrite() {
    /* Write new index */
    setState(s_writing_index);
    headerWrite(INDEX_OFFSET + !currentIndex, index);
  }

  void writeSelector() {
    currentIndex = !currentIndex;
    eepromLine[0] = currentIndex;
    setState(s_writing_selector);
    headerWrite(SELECTOR_OFFSET, eepromLine);
  }

  void writeHeader() {
    if (noHeader)
      {
	/* Only need to write header if there's no valid one around */
	struct header *config = (struct header *)eepromLine;

	config->cookie = COOKIE;
	config->ndataSets = ndataSets;
	config->dataLength = dataLength;
	setState(s_writing_header);
	headerWrite(HEADER_OFFSET, eepromLine);
      }
    else
      endWrite();
  }

  void startNextWrite() {
    /* Writing data from beyond the user's array should be fine ? */
    /* minor worry: what happens at end of SRAM ? */
    if (!call EEPROMWrite.write(userLine, userData))
      {
	writeResult = FAIL;
	endWrite();
      }
  }

  void writeDone() {
    if (userBytes < TOS_EEPROM_LINE_SIZE)
      {
	commitWrite();
      }
    else
      {
	userLine++;
	userData += TOS_EEPROM_LINE_SIZE;
	userBytes -= TOS_EEPROM_LINE_SIZE;
	startNextWrite();
      }
  }

  command result_t CheckpointWrite.write(uint8_t dataSet, uint8_t *data) {
    uint8_t old_free_set;

    if (state != s_ready || dataSet >= ndataSets ||
	!call EEPROMWrite.startWrite())
      return FAIL;

    setState(s_writing);

    /* Update index */
    old_free_set = freeDataSet;
    freeDataSet = index[dataSet];
    index[dataSet] = old_free_set;

    userData = data;
    userBytes = dataLength;
    userLine = eepromBase + DATA_OFFSET +
      old_free_set * linesPerSet(dataLength);
    writeResult = SUCCESS;
    startNextWrite();

    return SUCCESS;
  }

  event result_t EEPROMWrite.writeDone(uint8_t *buffer) {
    switch (state)
      {
      case s_writing:
	writeDone();
	break;
      case s_writing_index:
	writeSelector();
	break;
      case s_writing_selector:
	writeHeader();
	break;
      case s_writing_header:
	endWrite();
	break;
      default:
	/* BUG */
	break;
      }
    return SUCCESS;
  }
}
