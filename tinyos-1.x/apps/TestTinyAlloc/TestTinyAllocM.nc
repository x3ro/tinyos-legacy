// $Id: TestTinyAllocM.nc,v 1.2 2003/10/07 21:45:24 idgay Exp $

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

/* Authors:		Sam Madden, Phil Levis
 * Date last modified:  6/25/02
 *
 */

/**
 * @author Sam Madden
 * @author Phil Levis
 */


module TestTinyAllocM {
  provides {
    interface StdControl;
  }
  uses {
    interface MemAlloc;
    interface Timer;
    interface Leds;
  }
}

implementation {
  int8_t didFirst;
  Handle first;
  int8_t didSecond;
  Handle second;
  int8_t didThird;
  Handle third;
  int8_t compacted;
  int8_t didRealloc;
  int8_t didCompact;
  
  int strcpy(int8_t* dest, const int8_t* src) {
    int16_t cnt = 0;
    do {
      dest[cnt] = src[cnt];
      cnt++;
    } while (src[cnt-1] != 0);
    return cnt - 1;
  }

  int strcmp(int8_t* one, const int8_t* two) {
    int16_t cnt = 0;
    do {
      if (one[cnt] < two[cnt]) {
	return -1;
      }
      else if (one[cnt] > two[cnt]) {
	return 1;
      }
      else if (one[cnt] == 0 &&
	       two[cnt] == 0) {
	return 0;
      }
      cnt++;
    } while(1);
  }
  
  command result_t StdControl.init() {
    didFirst = 0;
    didSecond = 0;
    didThird = 0;
    didRealloc = 0;
    compacted = 0;
    call Leds.init();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call Leds.redToggle();
    if (!didFirst) {
      dbg(DBG_USR1, "TestTinyAlloc: Allocating 10 bytes for handle 1.\n");
      call MemAlloc.allocate(&first, 10);
    } else if (!didSecond) {
      dbg(DBG_USR1, "TestTinyAlloc: Allocating 20 bytes for handle 2.\n");
      call MemAlloc.allocate(&second, 20);
    } else if (!didThird) {
      dbg(DBG_USR1, "TestTinyAlloc: Copying \"Sam was here.\" into handle 2.\n");
      strcpy(*second,"Sam was here.");
      dbg(DBG_USR1, "TestTinyAlloc: Freeing handle 1.\n");
      call MemAlloc.free(first);
      dbg(DBG_USR1, "TestTinyAlloc: Allocating 30 bytes for handle 3.\n");
      call MemAlloc.allocate(&third, 30);
    } else if (!didRealloc) {
      dbg(DBG_USR1, "TestTinyAlloc: Reallocating 40 bytes for handle 2.\n");
      call MemAlloc.reallocate(second, 40);
    } else if (!didCompact) {
      dbg(DBG_USR1, "TestTinyAlloc: Compacting.\n");
      call MemAlloc.compact();
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 1024);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t MemAlloc.allocComplete(HandlePtr handle, result_t complete) {
    //printf("Something completed\n");
    if (complete) {
      if (handle == &first) {
	call Leds.greenToggle();
	dbg(DBG_USR1, "TestTinyAlloc: Alloc on handle 1 completed.\n");
	//TOS_CALL_COMMAND(ALLOC_DEBUG)();
	didFirst = 1;
      }
      else if (handle == &second) {
	if (didSecond) {
	  //printf("realloced, SECOND = %s\n", *VAR(second));
	  call Leds.greenToggle();
	  dbg(DBG_USR1, "TestTinyAlloc: Realloc on handle 2 completed.\n");
	  didRealloc = 1;
	  //TOS_CALL_COMMAND(ALLOC_DEBUG)();
	}
	else {
	  call Leds.greenToggle();
	  dbg(DBG_USR1, "TestTinyAlloc: Alloc on handle 2 completed.\n");
	  //TOS_CALL_COMMAND(ALLOC_DEBUG)();
	  didSecond = 1;
	}
      }
      else if (handle == &third) {
	call Leds.greenToggle();
	dbg(DBG_USR1, "TestTinyAlloc: Alloc on handle 3 completed.\n");
	//TOS_CALL_COMMAND(ALLOC_DEBUG)();
	didThird = 1;
      }
      else {
	call Leds.yellowOn();
	dbg(DBG_USR1, "TestTinyAlloc: Unknown handle returned.\n");
	//printf("Unknown handle returned.\n");
      }
    }
    else  {
      call Leds.yellowOn();
      dbg(DBG_USR1, "TestTinyAlloc: Operation failed..\n");
      //printf("Failed to alloc\n");
    }
    return SUCCESS;
  }

  event result_t MemAlloc.reallocComplete(Handle h, result_t complete) {
    if (h == first) {
      signal MemAlloc.allocComplete(&first, complete);
    }
    if (h == second) {
      signal MemAlloc.allocComplete(&second, complete);
    }
    if (h == third) {
      signal MemAlloc.allocComplete(&third, complete);
    }
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete() {
    //call Leds.yellowToggle();
    //printf("Compact complete\n");
    //  printf("Second = %s\n",*VAR(second));
    //call Leds.redOff();
    // call Leds.yellowOff();
    //call Leds.greenOff();
    call Leds.redOn();
    if (strcmp(*second, "Sam was here.") == 0) {
      call Leds.greenToggle();
      didCompact = 1;
      dbg(DBG_USR1, "TestTinyAlloc: Compaction didn't corrupt handle 2.\n");
    }
    else {
      dbg(DBG_USR1, "TestTinyAlloc: Compaction corrupted handle 2.\n");
      didCompact = 1;
      call Leds.yellowOn();
    }
    //TOS_CALL_COMMAND(ALLOC_DEBUG)();
    //   TOS_CALL_COMMAND(UNLOCK)(&VAR(second));
    //call MemAlloc.compact();
    return SUCCESS;
  }
}
