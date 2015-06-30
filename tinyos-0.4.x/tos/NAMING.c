/*									tab:4
 * NAMING.c
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
 * This component allows the naming scheme on a mote to be changed.  Some
 * useful naming schemes include those of random IDs, unique IDs, IDs based 
 * on location, IDs based on available sensors, or IDs based on current 
 * sensor values.  In order to create one's own naming scheme, one must write 
 * a component that handles the NAMING_GENERATE_ADDR event.  The 
 * NAMING_SCHEME_UNIQUE_ID component provides an example of this.
 */

#include "tos.h"
#include "NAMING.h"

#define TOS_FRAME_TYPE NAMING_frame
TOS_FRAME_BEGIN(NAMING_frame) {
  char scheme;     // current naming scheme
}
TOS_FRAME_END(NAMING_frame);

char TOS_COMMAND(NAMING_INIT)(){
  return 1;
}

char TOS_COMMAND(NAMING_START)(){
  return 1;
}


char TOS_COMMAND(NAMING_SET_NAMING_SCHEME)(char scheme){
  VAR(scheme) = scheme;
  // all of the available naming schemes handle this event
  TOS_SIGNAL_EVENT(NAMING_GENERATE_ADDR)();
  return 1;
}

char TOS_COMMAND(NAMING_GET_NAMING_SCHEME)(){
  return VAR(scheme);
}

// this event is signalled by the naming scheme component that handles
// the NAMING_GENERATE_ADDR event
char TOS_EVENT(NAMING_ADDR_READY)(short addr) {
  TOS_LOCAL_ADDRESS = addr;
  return 1;
}
