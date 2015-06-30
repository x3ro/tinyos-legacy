/*
    StdOut module - module that buffers and perhaps eventually will do some
    printf like thing.
    Copyright (C) 2002 Mads Bondo Dydensborg <madsdyd@diku.dk>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
/*
 * Simple StdOut component, uses Uart interface, buffers into 200 char buffer
 */

/**
 * Simple StdOut component that uses Uart interface.
 * <p>This configuration maps onto the uart that is normally used to connect onto 
 * a pc.</p>
 *
 * <p>Please note that this component blocks interrupts and copies
 * data - it is not a very good TinyOS citizen. Its a debug tool.</p>
 */
module StdOutM
{
  provides interface StdOut;
  uses interface HPLUART as UART;
}

#define STDOUT_BUFFER_SIZE 200 // This will probably not be enough always.

// Use the leds to print
//#define DEBUG

implementation
{
  /** The buffer used to buffer into. This is 200 bytes */
  char buffer[STDOUT_BUFFER_SIZE];
  char * bufferhead;
  char * buffertail;
  char * bufferend;
  int isOutputting;
  
  int count;

  /* Init */
  command result_t StdOut.init() {
    dbg(DBG_USR1, "StdOut starting ......\n");  
    call UART.init(); 

    atomic {
      bufferhead   = buffer;
      buffertail   = buffer;
      bufferend    = buffer + STDOUT_BUFFER_SIZE;
      isOutputting = FALSE;
      count        = 0;
    }
    return SUCCESS;

  }

  command result_t StdOut.done() {
    call UART.stop();
    return SUCCESS;
  }

  /* Add a string to the circular buffer. The string must be null-terminated.
     The number of chars written will be returned (not including the trailing \0).
  */
  async command int StdOut.print(const char * str) {
    /* Oh, the horror */
    int na_countret;
    atomic {
      bool return_flag = FALSE;
      int countret = 0;
      dbg(DBG_USR1, "StdOut print \"%s\"\n", str);

      /* Split into two passes - tail after head or before */
      if (buffertail >=  bufferhead) {
	while ((buffertail < bufferend) && (*str !=0)) {
	  // while ((buffertail < bufferend) && (*buffertail++ = *str)) {
	  *buffertail = *str;
	  ++buffertail;
	  //	  dbg(DBG_USR1, "StdOut print - copying \"%c\"\n", *str);
	  ++str;
	  ++countret;
	};
	/* Did we reach the end of the buffer ? */
	if (buffertail == bufferend) {
	  buffertail = buffer;
	} else {
	  /* Done with the string */
	  if (!isOutputting) {
	    //	    dbg(DBG_USR1, "StdOut - putting \"%c\"\n", *bufferhead);
	    call UART.put(*bufferhead);
	    isOutputting = TRUE; // Race condition!
	  }
	  return_flag = TRUE;
	  // return countret;
	}
      } /* buffertail >= buffertail */


      if (!return_flag) {
	//	dbg(DBG_USR1, "StdOut print - past bufferend \"%s\"\n", str);
	/* If we reach here, there are more string, and buffertail <= bufferhead */
	while (buffertail < bufferhead && (*str != 0)) {
	  *buffertail = *str;
	  ++buffertail;
	  ++str;
	  ++countret;
	};
	
	if (!isOutputting) {
	  call UART.put(*bufferhead);
	  isOutputting = TRUE; // Race condition!
	}
	/* Did we reach the end of the buffer ? */
	if (buffertail == bufferhead) {
	  if (!isOutputting) {
	    //	    dbg(DBG_USR1, "StdOut - putting \"%c\"\n", *bufferhead);
	    call UART.put(*bufferhead);
	    isOutputting = TRUE; // Race condition!
	  }
	  return_flag = TRUE;
	  // return countret;
	}
      }
      
      if (!return_flag) {
	/* Done with the string */
	if (!isOutputting) {
	  //	  dbg(DBG_USR1, "StdOut - putting \"%c\"\n", *bufferhead);
	  call UART.put(*bufferhead);
	  isOutputting = TRUE; // Race condition!
	}
	return_flag = TRUE;
	// return countret;
      }
      na_countret = countret;
    } /* Atomic */
    
    return na_countret;
  }

  /* Add a hex number to the circular buffer 
     - code is meant to be easy to read */
  async command int StdOut.printHex(uint8_t c) {
    char str[3];
    uint8_t v;
    
    /* Left digit */
    v = (0xF0 & c) >> 4;
    if (v < 0xA) {
      str[0] = v + '0';
    } else {
      str[0] = v - 0xA + 'A';
    }
    
    /* Right digit */
    v = (0xF & c);
    if (v < 0xA) {
      str[1] = v + '0';
    } else {
      str[1] = v - 0xA + 'A';
    }
    str[2] = 0;
    
    return call StdOut.print(str);
  }

  /* Add a word number to the circular buffer as hex
     - code is meant to be easy to read */
  async command int StdOut.printHexword(uint16_t c) {
    return call StdOut.printHex((0xFF00 & c) >> 8) 
      + call StdOut.printHex(0xFF & c);
  }

  /* Add a long number to the circular buffer as hex
     - code is meant to be easy to read */
  async command int StdOut.printHexlong(uint32_t c) {
    return call StdOut.printHex((0xFF000000 & c) >> 24) 
      + call StdOut.printHex((0xFF0000 & c) >> 16) 
      + call StdOut.printHex((0xFF00 & c) >> 8) 
      + call StdOut.printHex(0xFF & c);
  }

  /** Dump an array of hex's
   * 
   * \param ptr - array of uint8_t values
   * \param count - count of values in array
   * \param sep - optional seperator string

   * Always return succes, even if something went wrong.
   */
  async command result_t StdOut.dumpHex(uint8_t ptr[], uint8_t countar, char * sep) {
    int i;
    for (i = 0; i < countar; i++) {
      if (i != 0) { 
	call StdOut.print(sep);
      }
      call StdOut.printHex(ptr[i]);
    }
    return SUCCESS;
  }
  

  /* Handle emptying the buffer - the one in head have now been outputted 
     and we need to output the next, if needed. */
  async event result_t UART.putDone() {
    //    dbg(DBG_USR1, "StdOut putDone\n");
    atomic {
      /* Adjust bufferhead */
      ++bufferhead;
      ++count;
      if (bufferhead == bufferend) {
	bufferhead = buffer;
      }
      /* Check for more bytes */
      if (bufferhead != buffertail) {
	//	dbg(DBG_USR1, "StdOut - putting \"%c\"\n", *bufferhead);
	call UART.put(*bufferhead);
	isOutputting = TRUE;
      } else {
	isOutputting = FALSE;
      }
    }
    return SUCCESS;
  }

  default async event result_t StdOut.get(uint8_t data) {
       return SUCCESS;
  }

  /* Handle getting data such that the user of this interface can get data. */
  async event result_t UART.get(uint8_t data) {
    signal StdOut.get(data);
    return SUCCESS;
  }
}
