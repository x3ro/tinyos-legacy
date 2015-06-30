/*									tab:4
 * NAMING_SCHEME_UNIQUE_ID.c
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:   Solomon Bien
 * History:   created 8/14/2001
 *
 *
 * This component is the implementation of a unique ID naming scheme, using 
 * the NAMING component.  It assumes that a unique ID is stored on the first 
 * line of the EEPROM.
 */

#include "tos.h"
#include "NAMING_SCHEME_UNIQUE_ID.h"

// this is the type of the naming scheme--each naming scheme should have a 
// distinct type
#define NAMING_SCHEME_UNIQUE_ID   0

#define TOS_FRAME_TYPE NAMING_SCHEME_UNIQUE_ID_frame
TOS_FRAME_BEGIN(NAMING_SCHEME_UNIQUE_ID_frame) {
  char frag_map[16];
  char myType;
  short addr;
}
TOS_FRAME_END(NAMING_SCHEME_UNIQUE_ID_frame);

char TOS_COMMAND(NAMING_SCHEME_UNIQUE_ID_INIT)(){
  TOS_CALL_COMMAND(NAMING_SCHEME_UNIQUE_ID_SUB_INIT)();
  VAR(myType) = NAMING_SCHEME_UNIQUE_ID;
  return 1;
}

char TOS_COMMAND(NAMING_SCHEME_UNIQUE_ID_START)(){
  TOS_CALL_COMMAND(NAMING_SCHEME_UNIQUE_ID_SUB_START)();

  // this reads the unique ID from the first line of the EEPROM
  TOS_CALL_COMMAND(NAMING_SCHEME_UNIQUE_ID_SUB_READ_LOG)(0, VAR(frag_map));
  VAR(addr) = VAR(frag_map)[0] & 0xff;
  VAR(addr) |= VAR(frag_map) [1]<< 8;
  
  return 1;
}

// handler for the NAMING_GENERATE_ADDR event
char TOS_EVENT(NAMING_SCHEME_UNIQUE_ID_GENERATE_ADDR)() {
  // if the currently active naming scheme is my type, then pass back the
  // address that I generated for this node
  if(TOS_CALL_COMMAND(NAMING_SCHEME_UNIQUE_ID_SUB_GET_NAMING_SCHEME)() == VAR(myType)) {
    TOS_SIGNAL_EVENT(NAMING_SCHEME_UNIQUE_ID_ADDR_READY)(VAR(addr));
  }
  return 1;
}




