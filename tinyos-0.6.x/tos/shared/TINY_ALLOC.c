/*									tab:4
 *
 *
 * "Copyright (c) 2002 Sam Madden and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Author:  Sam Madden (madden@cs.berkeley.edu)
 *
 *
 */

/* TINY_ALLOC is a simple, handle-based compacting memory manager.  It
allocates bytes from a fixed size frame and returns handles (pointers
to pointers) into that frame.  Because it uses handles, TINY_ALLOC can
move memory around in the frame without changing all the external
references.  Moving memory is a good thing because it allows frame
compacting and tends to reduce wasted space.  Handles can be accessed
via a double dereference (**), and a single dereference can be used
wherever a pointer is needed, but if a single dereference is to be
stored, the handle must be locked first as otherwise TINY_ALLOC may
move the handle and make the reference invalid.

   Like all good TinyOS programs, TINY_ALLOC is split phase with
respect to allocation and compaction.  Allocation/reallocation completion is
signalled via a TINY_ALLOC_COMPLETE signal and compaction via a
TINY_ALLOC_COMPACT_COMPLETE signal.  All other operations complete and
return in a single phase. Note that compaction may be triggered
automatically from allocation; in this case a COMPACT_COMPLETE event
is not generated.

Handles are laid out in the frame as follows:

   [LOCKED][SIZE][user data] 

Where: 
    LOCKED     : a single bit indicating if the handle is locked 
    SIZE       : 7 bits representing the size of the handle 
    user data  : user-requested number of bytes (**h) points to
                 [user data], not [LOCKED].

   Calling TOS_COMMAND(TINY_ALLOC_SIZE(h)) returns the size of [user
data] (note that the internal function size() returns the size of the
entire handle, including the header byte.)
*/   
   


#include "tos.h"
#include "alloc.h"
#include "TINY_ALLOC.h"
#include "dbg.h"


#define FRAME_SIZE 1024 //size of heap
#define FREE_SIZE (FRAME_SIZE >> 3)
#define MAX_SIZE 127 //largest block we can allocate (DON'T CHANGE!)
#define MAX_HANDLES 32 //maximum number of outstanding handles

#define TOS_FRAME_TYPE TINY_ALLOC_frame
TOS_FRAME_BEGIN(TINY_ALLOC_frame) {
  unsigned char frame[FRAME_SIZE]; //the heap
  unsigned char free[FREE_SIZE]; //free bit map
  char allocing; //are we allocating?
  char compacting; //are we compacting?
  short size; //how many bytes are we allocing?
  short last; //where were we in the last task invocation
  Handle *handle; //handle we are allocating
  char **tmpHandle; //temporary handle for realloc
  Handle oldHandle; //old user handle for realloc
  char *handles[MAX_HANDLES]; //handles we know about
  char reallocing; //are we reallocing
  char compacted; //already compacted this allocation
  char needFree; //looking for free bits in current byte?
  short contig; //contig bytes seen so far 
  short startByte; //start of free section (in bytes)

  /* DEBUGGING FIELDS */
  //  char buf[512];
  //short cur;
  //short len;
}
TOS_FRAME_END(TINY_ALLOC_frame);

//some internal functions
TOS_TASK(allocTask);
TOS_TASK(compactTask);
void doAlloc(short startByte, short endByte);
void shiftUp(Handle handle, int bytes);
short start_offset(char *ptr);
void setFreeBits(short startByte, short endByte, char on);
void remapAddr(char *oldAddr, char *newAddr);
char isValid(Handle h);
char size(char *p);
char is_locked(char *ptr);
char finish_realloc(Handle *handle, char success);
Handle getH(char *p);
short getNewHandleIdx();

//void sendNext();

// ------------------------------- TINY_ALLOC_INIT ----------------------------- //
char TOS_COMMAND(TINY_ALLOC_INIT)() {
  short i;
  VAR(allocing) = 0;
  VAR(reallocing) = 0;
  for (i = 0; i < FREE_SIZE >> 4; i++) {
    ((long *)VAR(free))[i] = 0;
  }
  for (i = 0; i < MAX_HANDLES; i++) {
    VAR(handles)[i] = 0;
  }
  /* DEBUGGING
  TOS_CALL_COMMAND(CHILD_INIT)();
  */
  return 0;
}

// ------------------------------- TINY_ALLOC_ALLOC ----------------------------- //
/* Allocate a buffer of the specified size into the specified handle
   Return 0 on failure, 1 on success (result pending)
   Sinals TINY_ALLOC_COMPLETE when allocation is finished 
*/
char TOS_COMMAND(TINY_ALLOC_ALLOC)(Handle *handle, short size) {
  if (size > MAX_SIZE || VAR(allocing)) return 0;
  VAR(allocing) = 1;
  VAR(size) = size + 1; //need an extra byte for header info


  VAR(handle) = handle;
  VAR(compacted) = 0;
  VAR(needFree) = 0;
  VAR(contig) = 0;
  VAR(last) = 0;
  VAR(startByte) = 0;
  TOS_POST_TASK(allocTask);
  return 1;
}

/* Task that passes through memory, trying to 
   allocate bytes
*/
TOS_TASK(allocTask) {
  short endByte;
  short i, j;


  i = VAR(last)++;
  if (i == FREE_SIZE) {
    if (VAR(compacted)) { //try to compact if can't allocate
      //already compacted -- signal failure
      VAR(allocing) = 0;
      if (VAR(reallocing)) {
	finish_realloc(VAR(handle), 0);
      } else
	TOS_SIGNAL_EVENT(TINY_ALLOC_COMPLETE)(VAR(handle), 0);
    } else {
      VAR(compacted) = 1;
      CLR_RED_LED_PIN();
      //try compacting
      TOS_POST_TASK(compactTask);
    }
    return;
  }

  if (VAR(needFree) && VAR(free)[i] != 0xFF) { //some free space
    VAR(startByte) = i << 3;
    for (j = 0; j < 8; j++) {
      if (VAR(free)[i] & (1 << j)) {
	if (VAR(contig) >= VAR(size)) { //is enough free space
	  //alloc it and return
	  endByte = VAR(startByte) + VAR(size);
	  doAlloc(VAR(startByte), endByte);
	  return;
	} else {
	  VAR(startByte) += (VAR(contig) + 1);
	  VAR(contig) = 0;
	}
      } else {
	VAR(contig)++;
      }
    }
    if (VAR(contig) >= VAR(size)) {
      endByte = VAR(startByte) + VAR(size);
      doAlloc(VAR(startByte),endByte);
      //alloc it and return
      return;
    } else {
      //some free space at end of byte, but need more
      VAR(needFree) = 0;
    }
  } else if (VAR(needFree) == 0) { //needFree sez there are free bits
    //in the current byte, and we should scan to find them on
    //the next pass
    if (VAR(free)[i] == 0) VAR(contig) += 8;
    else {
      for (j = 0; j < 8; j++) {
	if ((VAR(free)[i] & (1 << j)) == 0) {
	  VAR(contig)++;
	}
	else break;
      }
    }
    if (VAR(contig) >= VAR(size)) {
      endByte = VAR(startByte) + VAR(size);
      doAlloc(VAR(startByte), endByte);
      //alloc it and return
      return;
    } else if (VAR(free)[i] != 0) {
      VAR(contig) = 0;  //didn't find the needed amount of space
      VAR(needFree) = 1;
      VAR(last)--; //retry this byte
    }
    
  }
  TOS_POST_TASK(allocTask);
  
}

  /* Allocate the bytes from startByte to endByte to VAR(handle),
     set state to stop allocating, and return the handle to the user
     mark header byte to include length (including header) and status
  */
void doAlloc(short startByte, short endByte) {
  short newIdx = getNewHandleIdx();
  if (newIdx == -1) {
    TOS_SIGNAL_EVENT(TINY_ALLOC_COMPLETE)(VAR(handle),0); //signal failure
    return;
  }

  VAR(frame)[startByte] = (endByte - startByte) & 0x7F;
  
  //WARNING -- not going through standard accessors
  
  VAR(handles)[newIdx] = (char *)((&VAR(frame)[startByte]) + 1);
  *VAR(handle) = &VAR(handles)[newIdx];
  
  //mark bits
  setFreeBits(startByte,endByte, 1);
  
  VAR(allocing) = 0;
  if (VAR(reallocing)) {
    finish_realloc(VAR(handle),1);
  } else
    TOS_SIGNAL_EVENT(TINY_ALLOC_COMPLETE)(VAR(handle), 1);
  
}


// ------------------------------- TINY_ALLOC_COMPACT ----------------------------- //

/* Compact the buffer */
void TOS_COMMAND(TINY_ALLOC_COMPACT)(void) {
  if (!VAR(compacting) && !VAR(allocing)) 
    TOS_POST_TASK(compactTask);
}

/** Task that compacts out free space in the current buffer */
TOS_TASK(compactTask) {
  short i;
  unsigned char c;
  char *p;
  char endFree = 0;

  if (VAR(compacting) == 0) {
    VAR(contig) = 0;
    VAR(last) = 0;
    VAR(compacting) = 1;
    VAR(startByte) =0;
  }
  c = VAR(free)[VAR(last)++];
  
  //process:  scan forward in free bitmap, looking for runs of free space
  //at end of run, move bytes up

  if (c == 0) {  //byte not used at all
    VAR(contig) += 8;
  } else {
    if (c != 0xFF){ //byte not fully used
      for (i = 0; i < 8; i++) {
	if ((c & (1 << i)) == 0) {
	  VAR(contig)++;
	  endFree = 1; //endFree sez the last bit of this byte was free
	} else if (VAR(contig) == 0) { //bit not free, no compaction to do
	  VAR(startByte)++;
	  endFree = 0;
	} else {  //bit not free, but need to compact
	  endFree = 0;
	  break;
	}
      }
    }

    if (VAR(contig) > 0 && !endFree) { //need to compact?
      p = &(VAR(frame)[VAR(startByte) + VAR(contig) + 1]); //get the handle
      if (!is_locked(p)) {
	printf("compacting, from %d, %d bytes\n", VAR(startByte) + VAR(contig) + 1,
	       VAR(contig));
	shiftUp(getH(p), VAR(contig));

	//TOS_CALL_COMMAND(ALLOC_DEBUG)();
	VAR(startByte) += (size(p) >> 3) << 3;
      } else {
	printf ("SOMETHING LOCKED, at %d", VAR(startByte) + VAR(contig) + 1);
	VAR(startByte) += ((size(p) + VAR(contig)) >> 3) << 3;
	//make sure we don't retry the same byte again if this handle is locked
	//note that this can lead to holes of fewer than 8 bytes at the end of 
	//allocations which occupy fewer than 8 bytes
	if (VAR(startByte) >> 3 == VAR(last -1)) VAR(startByte) += 8;
      }
      VAR(last) = (VAR(startByte) >> 3);
      VAR(startByte) = VAR(last) << 3;

      printf("\nlast = %d, startByte = %d\n", VAR(last), VAR(startByte));

      VAR(contig) = 0;
    } else if (!endFree) { //not compacting, move to next byte 
      VAR(startByte) += 8;
      VAR(contig) = 0;
    }
  }

  //scanned the whole thing
  if (VAR(last) == FREE_SIZE) {
    VAR(compacting) = 0;
    VAR(last) = 0;
    VAR(contig) = 0;
    VAR(needFree) = 0;
    VAR(startByte) = 0;
    if (VAR(allocing)) {
      TOS_POST_TASK(allocTask); //finish allocation
    } else {
      TOS_SIGNAL_EVENT(TINY_ALLOC_COMPACT_COMPLETE)();
    }
  } else
    TOS_POST_TASK(compactTask); //keep compacting
}



/** Move the handle up (towards the beginning of the buffer)
    by the specified number of bytes.  No bounds checking,
    so probably shouldn't be used externally.  :-)
*/
void shiftUp(Handle handle, int bytes) {
  short start = start_offset(deref(handle)), 
    end = start + size(deref(handle)), newstart, newend;

  char *p = deref(handle) -1;
  char *startp= deref(handle) -1 - bytes, *q;
  int cnt = size(deref(handle)) + 1; //dont forget size / state byte
  
  q = startp;
  while(cnt--) {
    *q++ = *p++;
  }

  remapAddr(*handle, startp + 1);
  *handle = startp + 1;

  newstart = start_offset(deref(handle));
  newend = newstart + size(deref(handle));

  //now, have to offset free bytes
  //do it by unsetting old bits, setting new ones
  setFreeBits(start,end,0);
  setFreeBits(newstart,newend,1);
}

// ------------------------------- TINY_ALLOC_FREE ----------------------------- //
/* Deallocate the specified handle */
short TOS_COMMAND(TINY_ALLOC_FREE)(Handle handle) {
  long start ;
  long end;
  short i;

  if (!isValid(handle)) return 0;
#ifdef FULLPC
  start = ((long)(deref(handle)) - 1);
  start -=  (long)(&VAR(frame));

  end = start + (long)size(deref(handle));
  printf ("freeing from %d to %d", (short)start, (short)end);
#else //pointers are different sizes on motes & PCs!
  start =  (long)((short)(deref(handle)) - 1);
  start -= (long)(&VAR(frame));

  end = start + (long)size(deref(handle));
#endif

  setFreeBits(start,end,0);

  for (i = 0; i < MAX_HANDLES; i++) {
    if (&VAR(handles)[i] == handle) {
      //note that setting to 0 here means we'll have to 
      //walk the handle list looking for free slots later
      //we can't just keep a dense list of used handles
      //since the application maintains pointers into
      //the handle list
      VAR(handles)[i] = 0;
      break;
    }
  }
  
  return (end - start);
}

// ------------------------------- TINY_ALLOC_REALLOC ----------------------------- //
//Change the size of the specified handle.
//If newSize > size(handle), change the size of the handle to the new size
// preserving the old data
//If newSize < size(handle), change the size of the handle and discard bytes
// at the end
char TOS_COMMAND(TINY_ALLOC_REALLOC)(Handle handle, short newSize) {
  short neededBytes = newSize + 1;
  char *p = *handle;

  if (neededBytes > MAX_SIZE) return 0; //error!

  if (neededBytes < size(*handle)) {
    short oldSize = size(*handle);

    //change the size of the handle
    ((char *)(p - 1))[0] = neededBytes & 0x7F;

    //unset the used bits at the end
    setFreeBits(start_offset(p) + neededBytes , start_offset(p) + oldSize, 0); 
    return 1;
  } else if (neededBytes > size(*handle) && !is_locked(*handle)) { //handle must be be bigger
    printf("REALLOCING\n"); //fflush(stdout);
    //for now, just allocate a new handle and copy the old handle over
    VAR(reallocing) = 1;
    VAR(oldHandle) = handle;
    return (TOS_CALL_COMMAND(TINY_ALLOC_ALLOC)(&VAR(tmpHandle), newSize) == 0);
  }
  return 0; //failure
}

//second half of split phase reallocation
  char finish_realloc(Handle *handle, char success) {
    VAR(reallocing) = 0;
    printf ("realloced, success = %d!\n\n",success); //fflush(stdout);
    if (success) {
      char *p = **handle;
      char *q = *VAR(oldHandle);
      short cnt = size(*VAR(oldHandle));
      printf("cnt = %d\n", cnt);//fflush(stdout);
      while(cnt--) {
	*p++ = *q++;
      }
      //clear bits the old handle used
      setFreeBits(start_offset(*VAR(oldHandle)), 
		  start_offset(*VAR(oldHandle)) + size(*VAR(oldHandle)), 0); 
      //remap old handle to the new handle
      remapAddr(*VAR(oldHandle), **handle);

      TOS_SIGNAL_EVENT(TINY_ALLOC_REALLOC_COMPLETE)(VAR(oldHandle), 1);
    } else {
      TOS_SIGNAL_EVENT(TINY_ALLOC_REALLOC_COMPLETE)(VAR(oldHandle), 0);
      return 0;
    }
    return 1;
  }

// ------------------------------- Lock / Unlock ----------------------------- //
/* Lock the handle */
void TOS_COMMAND(TINY_ALLOC_LOCK)(Handle handle) {
  char *ptr = deref(handle);
  ((char *)(ptr - 1))[0] |= 0x80;
}

/* Unlock the handle */
void TOS_COMMAND(TINY_ALLOC_UNLOCK)(Handle handle) {
  char *ptr = deref(handle);
  ((char *)(ptr - 1))[0] &= 0x7F;
}

/* Return 1 iff h is locked, 0 o.w. */
char TOS_COMMAND(TINY_ALLOC_IS_LOCKED)(Handle h) {
  return is_locked(*h);
}

/* Return 1 iff the handle referencing ptr is locked */
char is_locked(char *ptr) {
  return (char)(((char *)(ptr - 1))[0] & 0x80);
}

// ------------------------------- Utility Functions ----------------------------- //
/* Return the size of the handle h, excluding the header */
short TOS_COMMAND(TINY_ALLOC_SIZE)(Handle h) {
  return (size(*h) - 1);
  
}
/* Return the size of the handle referencing ptr 
   including the header 
*/
char size(char *ptr) {
  return (char)(((char *)(ptr - 1))[0] & 0x7F);
}


//return 1 iff the handle points to a valid loc, 0 o.w.
char isValid(Handle h) {
//pointers on motes are different size than on PC
#ifdef FULLPC
  return ((long)*h >= (long)(&VAR(frame))[0] && (long)*h < (long)&(VAR(frame)[FRAME_SIZE]));
#else
  return ((short)*h >= (short)(&VAR(frame))[0] && (short)*h < (short)&(VAR(frame)[FRAME_SIZE]));
#endif
}

//move all handles that used to point to oldAddr to
//point to newAddr
void remapAddr(char *oldAddr, char *newAddr) {
  short i;

  for (i = 0; i < MAX_HANDLES; i++) {
    if ((VAR(handles)[i]) == oldAddr) (VAR(handles)[i]) = newAddr;
  }
}


//return the handle with the address p
Handle getH(char *p) {
  short i;
  for (i = 0; i < MAX_HANDLES;i++) {
    if ((VAR(handles)[i]) == p) {
      return &VAR(handles)[i];
    }
  }
  return 0;
}

//find an unused handle slot
short getNewHandleIdx() {
  int i;
  for (i = 0; i < MAX_HANDLES; i++) {
    if ((VAR(handles)[i]) == 0) return i;
  }
  return -1;
}

/* Mark the free bits corresponding to the specified
   range of bytes in the allocation buffer.
*/
void setFreeBits(short startByte, short endByte, char on) {
  short leadInBits = (startByte - ((startByte >> 3) << 3));
  short leadOutBits = endByte - ((endByte >> 3) << 3);
  short i;
  short startFree = startByte >> 3;
  short endFree = endByte >> 3;
    
  printf ("Setting bits from %d to %d to %d\n", startByte, endByte, on);
  if (startFree == endFree) leadInBits = 8; //no leadin if both in same byte
  
  //unroll this for efficiency, since its called a lot
  if (on) {
    for (i = leadInBits; i < 8; i++) {
      VAR(free)[startFree] |= (1 << i);
    }
    for (i = 0; i < leadOutBits; i++) {
      VAR(free)[endFree] |=  (1 << i);
    }
    startFree ++;
    for (i = startFree; i < endFree; i++) {
      VAR(free)[i] = 0xFF;
    }
  } else { //! on
    for (i = leadInBits; i < 8; i++) {
      VAR(free)[startFree] &= (0xFF ^ (1 << i));
    }
    for (i = 0; i < leadOutBits; i++) {
      VAR(free)[endFree] &= (0xFF ^ (1 << i));
    }
    startFree ++;
    for (i = startFree; i < endFree; i++) {
      VAR(free)[i] = 0x00;
    }
  }
}
  

//return the offset in bits into free where this starts 
//include the header byte
short start_offset(char *ptr) {
#ifdef FULLPC
  long len = (long)ptr - (long)(&VAR(frame)[0]) - 1;
  return (short)(len);
#else
  short len = (short)ptr - (short)(&VAR(frame)[0]) - 1;
  return len;
#endif
}

// ------------------------------- Debugging Stuff ----------------------------- //
//currently disabled when not in PC mode

/* Print out the current free bitmap */
void TOS_COMMAND(ALLOC_DEBUG)(void) {

#ifdef FULLPC
  short i,j;
  printf("Debugging:");
  for (i = 0; i < FREE_SIZE; i++) {
    for (j = 0; j < 8; j++) {
      printf("%d:",(VAR(free)[i]&1<<j) > 0?1:0);
    }
    printf(",");
  }
  printf("\n\n");
  for (i = 0; i < FRAME_SIZE; i++) {
    printf("%c,",VAR(frame)[i]);
  }
#else
  /* DISABLED FOR DEBUGGING
     short i,j;
  VAR(buf)[0] = 0;
  for (i = 0; i < FREE_SIZE; i++) {
    for (j = 0; j < 8; j++) {
      strcat(VAR(buf),(VAR(free)[i]&1<<j) > 0?"1":"0");
      strcat(VAR(buf),":");
    }
    strcat(VAR(buf),",");
  }
  strcat(VAR(buf),"\n");
  VAR(cur) = 0;
  VAR(len) = strlen(VAR(buf));
  sendNext();
  */
#endif
}

/* DISABLED FOR DEBUGGING

   char TOS_EVENT(DUMMY)(void) {
   sendNext();
   return 1;
   }
   
   char TOS_EVENT(MY_RX)(char data, char anerror) {
   return 1;
   }
   

   char TOS_EVENT(TX_DONE)(char success) {
   sendNext();
   return 0;
   }

   void sendNext() {
   if (VAR(cur)++ > VAR(len)) return;
   TOS_CALL_COMMAND(TX)(VAR(buf)[VAR(cur)-1]);
   }

To debug, add the following lines to TINY_ALLOC.comp

HANDLES{
	char TX_DONE(char success);
	char DUMMY(void);
	char MY_RX(char data, char anerror);
};

USES{
	char TX(char c);
	char CHILD_INIT();
};

And the following to TINY_ALLOC.desc

UART:UART_TX_BYTE_READY TINY_ALLOC:TX_DONE
UART:UART_TX_BYTES TINY_ALLOC:TX
UART:UART_INIT TINY_ALLOC:CHILD_INIT
UART:UART_RX_BYTE_READY TINY_ALLOC:MY_RX
UART:UART_TX_DONE TINY_ALLOC:DUMMY


*/
