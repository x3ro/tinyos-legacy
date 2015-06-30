/*									tab:4
 * MoteInfoStructs.h
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
 
Public data structures used by MOTEINFO report schema, version, and id information
about motes to the outside world.

 Authors:  Sam Madden
 Date: 6/12/01
*/

#include "schema.h"

typedef struct{
  /* version is vers_major.vers_minor.  vers_project is a project identifier  */
  short src;
  short vers_project;
  char vers_major;
  char vers_minor;
} version_msg;

typedef struct{
  short src;
  char val;
} id_msg;

typedef struct{
  short src;
  char count;
  char index;
  Field schema;
} schema_msg;


typedef struct {
  char type;
} info_request_msg;

typedef enum {
  kSCHEMA_REQUEST = 0, kID_REQUEST = 1, kVERSION_REQUEST = 2
} MoteInfoMessageType;

